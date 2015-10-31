import Control.Monad
import Data.List
import Development.Shake
import Development.Shake.Command
import Development.Shake.FilePath
import Development.Shake.Util
import System.Directory (createDirectoryIfMissing)

buildDir = "_build"
tempDir = "_temp"
hakyllDir = "_site"
hakyllCacheDir = "_cache"

highlightLanguages :: [String]
highlightLanguages = ["bash", "css", "haskell", "javascript", "markdown", "sql", "xml", "dart"]

main :: IO ()
main = shakeArgs shakeOptions{shakeFiles="_build", shakeThreads=0} $ do
    phony "clean" $ do
        putNormal $ "Cleaning files in " ++ buildDir
        removeFilesAfter buildDir ["//*"]
        putNormal $ "Cleaning files in " ++ tempDir
        removeFilesAfter tempDir ["//*"]
        putNormal $ "Cleaning files in " ++ hakyllDir
        removeFilesAfter hakyllDir ["//*"]
        putNormal $ "Cleaning files in " ++ hakyllCacheDir
        removeFilesAfter hakyllCacheDir ["//*"]

    phony "build" $ do
        -- Statics
        forM_ statics $ \pattern -> do
            files <- getDirectoryFiles "." [pattern]
            need [buildDir </> x | x <- files]

        -- Demos
        demosFiles <- getDirectoryFiles "." ["demos//*"]
        need [buildDir </> x | x <- demosFiles, not $ ".git" `isPrefixOf` dropDirectory1 x]

        -- Favicons
        faviconsFiles <- getDirectoryFiles "." ["favicons//*"]
        need [buildDir </> dropDirectory1 x | x <- faviconsFiles]

        -- Styles
        need [buildDir </> "css/style.css", buildDir </> "css/print.css"]

        -- Map
        need [buildDir </> "map/world.json"]

        -- Scripts
        need
            [ buildDir </> "dart/s.js"
            , buildDir </> "dart/smap.js"
            , buildDir </> "dart/script.dart.js"
            , buildDir </> "dart/script-route-planner.dart.js"
            , buildDir </> "dart/script-map.dart.js"
            ]

        need ["site"]


    -- Statics
    forM_ statics buildStatic
    buildDemos
    buildFavicons

    buildStyles
    buildMap
    buildScripts

    buildSite

    where
        statics =
            [ "fonts/*"
            , "images//*.png", "images//*.jpg", "images//*.gif"
            , "robots.txt", "yandex-widget-manifest.json", "js/html5shiv.js", "map/data.json"
            ]

buildStatic pattern =
    buildDir </> pattern %> \out -> do
        let src = dropDirectory1 out
        copyFileChanged src out



buildDemos =
    buildDir </> "demos//*" %> \out -> do
        let src = dropDirectory1 out
        when (p src) $ copyFileChanged src out
    where
        p file = not $ ".git" `isPrefixOf` dropDirectory1 file



-- Copy favicons folder to root
buildFavicons =
    buildDir </> "*" %> \out -> do
        let src = "favicons" </> dropDirectory1 out
        exists <- doesFileExist src
        when exists $ copyFileChanged src out



-- Build styles
buildStyles =
    buildDir </> "css/*.css" %> \out -> do
        let src = "less" </> dropDirectory1 (dropDirectory1 out -<.> "less")
        files <- getDirectoryFiles "." ["less//*"]
        need files
        cmd "lessc" "--clean-css=advanced" "--include-path=less" src out



-- Build map
buildMap = do
    buildDir </> "map/world.json" %> \out -> do
        let countries = tempDir </> "countries.json"
        let subunits = tempDir </> "subunits.json"
        let regions = tempDir </> "regions.json"
        need [countries, subunits, regions]
        cmd "topojson" "-o" out "--id-property" "ADM_A3,SU_A3,adm1_code" "--simplify" "1e-6" "--" countries subunits regions

    tempDir </> "subunits.json" %> \out -> do
        liftIO $ removeFiles "." [out]
        let src = "map/ne_10m_admin_0_map_subunits/ne_10m_admin_0_map_subunits.shp"
        need [src]
        cmd Shell "ogr2ogr" "-f" "GeoJSON" out "-where" "\"ADM0_A3 = 'FRA'\"" src

    tempDir </> "countries.json" %> \out -> do
        liftIO $ removeFiles "." [out]
        let src = "map/ne_10m_admin_0_map_subunits/ne_10m_admin_0_map_subunits.shp"
        need [src]
        cmd Shell "ogr2ogr" "-f" "GeoJSON" out "-where" "\"ADM0_A3 != 'FRA' and ADM0_A3 != 'RUS' and ADM0_A3 != 'USA'\"" src

    tempDir </> "regions.json" %> \out -> do
        liftIO $ removeFiles "." [out]
        let src = "map/ne_10m_admin_1_states_provinces_lakes/ne_10m_admin_1_states_provinces_lakes.shp"
        need [src]
        cmd Shell "ogr2ogr" "-f" "GeoJSON" out "-where" "\"ADM0_A3 = 'RUS' or ADM0_A3 = 'USA'\"" src



-- Build scripts
buildScripts = do
    buildDir </> "dart/s.js" %> \out -> do
        content <- concatResources ["js/highlight.js/build/highlight.pack.js", "js/likely/likely.js"]
        writeFile' out content

    buildDir </> "dart/smap.js" %> \out -> do
        content <- concatResources ["js/d3/d3.min.js", "js/polyhedron.js", "js/topojson/topojson.min.js"]
        writeFile' out content

    "js/highlight.js/build/highlight.pack.js" %> \out ->
        cmd (Cwd "js/highlight.js") "node" "tools/build.js" highlightLanguages

    buildDart "dart/script.dart.js" "dart/web/main.dart"
    buildDart "dart/script-route-planner.dart.js" "dart/web/route-planner.dart"
    buildDart "dart/script-map.dart.js" "dart/web/map.dart"

    where
        concatResources resources = do
            content <- mapM readFile' resources
            return $ concat content

        buildDart res src =
            buildDir </> res %> \out -> do
                 files <- getDirectoryFiles "." ["dart/lib//*.dart", "dart/packages//*.dart", "dart/web//*.dart"]
                 need files
                 () <- cmd "dart2js" ("--out=" ++ out) "--minify" src
                 liftIO $ removeFiles "." [out -<.> "js.deps", out -<.> "js.map"]

buildSite =
    phony "site" $ do
        files <- getDirectoryFiles ""
            [ "comments/*.html"
            , "templates/*.html"
            , "route-planner/index.html"
            , "collections/*.txt"
            , "index.md"
            , "404.md"
            , "about.md"
            , "projects.md"
            , "post//*"
            , "dikmax-name"
            ]
        need files
        () <- cmd "./dikmax-name build"
        results <- getDirectoryFiles "" [hakyllDir <//> "*"]
        forM_ results (\file -> do
            let out = buildDir </> dropDirectory1 file
            liftIO $ createDirectoryIfMissing True (takeDirectory out)
            copyFileChanged file out)