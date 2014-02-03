{-# LANGUAGE CPP               #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TupleSections     #-}
import           Blaze.ByteString.Builder (toByteString)
import           Control.Monad (forM_, filterM, liftM, msum)
import           Data.Char
import           Data.Function (on)
import           Data.List (sortBy, intercalate, unfoldr, isSuffixOf, find, groupBy)
import qualified Data.Map as M
import           Data.Maybe
import           Data.Monoid (mappend, mconcat)
import           Data.Ord (comparing)
import qualified Data.Text as T
import qualified Data.Text.Encoding as T
import           Data.Time.Clock (UTCTime, getCurrentTime)
import           Data.Time.Format (formatTime, parseTime)
import           Hakyll hiding (buildPaginateWith, chronological, dateFieldWith, getItemUTC, getTags, paginateContext,
                    pandocCompiler, recentFirst)
import           System.FilePath (takeFileName)
import           System.Locale
import           Text.HTML.TagSoup (Tag(..))
import qualified Text.HTML.TagSoup as TS
import           Text.Pandoc
import           Text.Printf (printf)
import           Text.Regex (mkRegex, subRegex)
import           Text.XmlHtml
import           XmlHtmlWriter


--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    staticFilesRules
    lessCompilerRules
    commentsRules
    postsRules
    tagsPagesRules
    archiveRules
    indexPagesRules
    staticPagesRules
    feedRules
    sitemapRules

    match "templates/*" $ compile templateCompiler


--------------------------------------------------------------------------------
-- Defines
--------------------------------------------------------------------------------

#ifdef DEVELOPMENT

archiveTemplateName :: Identifier
archiveTemplateName = "templates/archive-development.html"
defaultTemplateName :: Identifier
defaultTemplateName = "templates/default-development.html"
indexTemplateName :: Identifier
indexTemplateName = "templates/index-development.html"
listTemplateName :: Identifier
listTemplateName = "templates/list-development.html"
postTemplateName :: Identifier
postTemplateName = "templates/post-development.html"

#else

archiveTemplateName :: Identifier
archiveTemplateName = "templates/archive.html"
defaultTemplateName :: Identifier
defaultTemplateName = "templates/default.html"
indexTemplateName :: Identifier
indexTemplateName = "templates/index.html"
listTemplateName :: Identifier
listTemplateName = "templates/list.html"
postTemplateName :: Identifier
postTemplateName = "templates/post.html"

#endif

--------------------------------------------------------------------------------
-- Archive
--------------------------------------------------------------------------------

archiveRules :: Rules ()
archiveRules = do
    ids <- getMatches "post/**"
    filteredIds <- filterM isPublished ids
    years <- mapM yearsMap filteredIds
    let ym = sortBy (\a b -> compare (fst b) (fst a)) $ yearsMap1 years
        firstYear = fst $ head ym
        fp year
            | year == firstYear = "archive/index.html"
            | otherwise = "archive/" ++ year ++ "/index.html"
        fp' year
            | year == firstYear = "/archive/"
            | otherwise = "/archive/" ++ year ++ "/"
    forM_ ym $ \(year, list) ->
        create [fromFilePath $ fp year] $ do
            route idRoute
            compile $ do
                posts <- recentFirst =<< loadAllSnapshots (fromList list) "content"
                months <- mapM monthsMap posts
                let yearCtx =
                        field "active" (\i -> if itemBody i == year then return "active" else fail "") `mappend`
                        field "href" (return . fp' . itemBody) `mappend`
                        bodyField "year"

                    mm = groupBy ((==) `on` fst) months

                    postsList i = do
                        tpl <- loadBody "templates/_post-archive.html"
                        str <- applyTemplateList tpl ctx items
                        item <- makeItem str
                            >>= loadAndApplyTemplate "templates/_post-list-archive.html" postCtx
                        return $ itemBody item
                        where
                            items = map snd $ filter (\m -> fst m == itemBody i) months
                            ctx = field "day" daysField `mappend` postCtx

                    monthsCtx =
                        field "posts" postsList `mappend`
                        {- listField "posts" postCtx postsList `mappend` -}
                        bodyField "month"

                    archiveCtx =
                        listField "years" yearCtx (mapM (makeItem . fst) ym) `mappend`
                        listField "months" monthsCtx (mapM (makeItem . fst . head) mm) `mappend`
                        pageCtx (defaultMetadata
                            { metaTitle = Just "Архив"
                            , metaDescription = "Список всех постов для \"быстрого поиска\""
                            , metaUrl = "/archive/"
                            })
                makeItem ""
                    >>= loadAndApplyTemplate archiveTemplateName archiveCtx
    where
        yearsMap i = do
            utc <- getItemUTC defaultTimeLocale i
            return (formatTime defaultTimeLocale "%Y" utc, [i])
        yearsMap1 = M.assocs . M.fromListWith (++)
        monthsMap i = do
            utc <- getItemUTC defaultTimeLocale $ itemIdentifier i
            return (formatTime timeLocale' "%B" utc, i)
        daysField i = do
            utc <- getItemUTC defaultTimeLocale $ itemIdentifier i
            return $ formatTime timeLocale' "%e" utc

isPublished :: (MonadMetadata m) => Identifier -> m Bool
isPublished identifier = do
    published <- getMetadataField identifier "published"
    return (published /= Just "false")

timeLocale' :: TimeLocale
timeLocale' = timeLocale
  { months =
    [ ("Январь", "янв")
    , ("Февраль", "фев")
    , ("Март", "мар")
    , ("Апрель", "апр")
    , ("Май", "май")
    , ("Июнь", "июн")
    , ("Июль", "июл")
    , ("Август", "авг")
    , ("Сентябрь", "сен")
    , ("Октябрь", "окт")
    , ("Ноябрь", "ноя")
    , ("Декабрь", "дек")
    ]
  }


--------------------------------------------------------------------------------
-- RSS feed
--------------------------------------------------------------------------------

feedPostCtx :: Context String
feedPostCtx =
    dateFieldWith defaultTimeLocale "pub-date" "%a, %d %b %Y %H:%M:%S GMT" `mappend`
    field "url" (return . identifierToUrl . toFilePath . itemIdentifier) `mappend`
    field "description" (return . escapeHtml . itemBody) `mappend`
    field "title" (\i -> do
      metadata <- getMetadata $ itemIdentifier i
      return $ escapeHtml $ maybe "" unwrap $ M.lookup "title" metadata) `mappend`
    defaultContext

feedRules :: Rules ()
feedRules =
    create ["feed.rss"] $ do
        route idRoute
        compile $ do
            posts <- fmap (take 10) . recentFirst =<<
                loadAllSnapshots "post/**" "content"
            time <- unsafeCompiler getCurrentTime
            lastItemTime <- getItemUTC defaultTimeLocale $ itemIdentifier $ head posts
            let postsCtx =
                    listField "posts" feedPostCtx (return posts) `mappend`
                    constField "build-date" (formatTime defaultTimeLocale "%a, %d %b %Y %H:%M:%S GMT" time) `mappend`
                    constField "pub-date" (formatTime defaultTimeLocale "%a, %d %b %Y %H:%M:%S GMT" lastItemTime)
            makeItem ("" :: String)
                >>= loadAndApplyTemplate "templates/rss.xml" postsCtx

--------------------------------------------------------------------------------
-- Static files
--------------------------------------------------------------------------------

-- DO NOT merge patterns with files! It won't work!
staticFilesRules :: Rules ()
staticFilesRules = do
    match "fonts/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "images/**" $ do
        route   idRoute
        compile copyFileCompiler

    match "demos/**" $ do
        route   idRoute
        compile copyFileCompiler

#ifdef DEVELOPMENT
    match "js/**" $ do
        route   idRoute
        compile copyFileCompiler
#else
    match (fromList ["js/script.js", "js/respond.min.js", "js/html5shiv.js"]) $ do
        route   idRoute
        compile copyFileCompiler
#endif

    match (fromList ["favicon.ico", "robots.txt"]) $ do
        route   idRoute
        compile copyFileCompiler

--------------------------------------------------------------------------------
-- LESS files
--------------------------------------------------------------------------------

lessCompilerRules :: Rules ()
lessCompilerRules = do
    match "less/*.less" $
        compile getResourceBody

    d <- makePatternDependency "less/**"
    rulesExtraDependencies [d] $ create ["css/style.css"] $ do
        route idRoute
        compile $ loadBody "less/style.less"
            >>= makeItem
            >>= withItemBody
              (unixFilter "lessc" ["--clean-css","-O2", "--include-path=less","-"]) -- TODO replace with --compress or --clean-css

--------------------------------------------------------------------------------
-- Posts
--------------------------------------------------------------------------------

postsRules :: Rules ()
postsRules =
    match "post/**" $ do
        route removeExtension

        compile $ do
            identifier <- getUnderlying
            -- Comments
            thread <- getMetadataField identifier "thread"
            comments <- getComments thread
            -- Metadata
            title <- getMetadataField identifier "title"
            tags <- getTags identifier
            description <- getMetadataField identifier "description"
            item <- pandocCompiler >>= saveSnapshot "content"
            let images = map (fromMaybe "") $ filter isJust $ map imagesMap $ TS.parseTags $ itemBody item

            time <- getItemUTC defaultTimeLocale identifier
            loadAndApplyTemplate "templates/_post.html" (postCtx `mappend` commentsField comments) item
                >>= loadAndApplyTemplate postTemplateName (postCtx `mappend` pageCtx (defaultMetadata
                    { metaTitle = fmap unwrap title
                    , metaUrl = '/' : identifierToUrl (toFilePath identifier)
                    , metaKeywords = tags
                    , metaDescription = maybe (cutDescription $ transformDescription $ escapeHtml $ TS.innerText $ TS.parseTags $
                        itemBody item) unwrap description
                    , metaType = FacebookArticle time tags images
                    }))



imagesMap :: Tag String -> Maybe String
imagesMap (TagOpen "img" attrs) = fmap snd $ find (\attr -> fst attr == "src") attrs
imagesMap _ = Nothing

--------------------------------------------------------------------------------
-- Comments
--------------------------------------------------------------------------------

commentsRules :: Rules ()
commentsRules =
    match "comments/*.html" $
        compile getResourceBody

getComments :: Maybe String -> Compiler [Item String]
getComments Nothing = return []
getComments (Just thread) = do
    ids <- getMatches "comments/*.html"
    filteredIds <- filterM compareThread ids
    loadAll (fromList filteredIds)
    where
        compareThread :: (MonadMetadata m) => Identifier -> m Bool
        compareThread identifier = do
            thread' <- getMetadataField identifier "thread"
            return (thread' == Just thread)


commentsField :: [Item String] -> Context String
commentsField items =
    field "comments" commentsList

    where
        ctx = bodyField "body" `mappend` metadataField

        commentsList _ = do
            tpl <- loadBody "templates/_comment.html"
            str <- applyTemplateList tpl ctx items
            item <- makeItem str
                >>= loadAndApplyTemplate "templates/_comments-list.html" postCtx
            return $ itemBody item

--------------------------------------------------------------------------------
-- Index pages
--------------------------------------------------------------------------------

indexPagesRules :: Rules ()
indexPagesRules = do
    match "index.md" $
        compile pandocCompiler

    paginate <- buildPaginateWith 5 getPageIdentifier "post/**"
    d <- makePatternDependency "post/**"
    rulesExtraDependencies [d] $ paginateRules paginate $ \page ids -> do
        route addIndexRoute
        compile $ if page == 1
            then do
                posts <- recentFirst =<< loadAllSnapshots ids "content"
                topPost <- loadBody "index.md"
                let postsCtx =
                        constField "body" topPost `mappend`
                        listField "posts" postWithCommentsCountCtx (return posts) `mappend`
                        paginateContext paginate `mappend`
                        pageCtx (defaultMetadata
                            { metaDescription = "Мой персональный блог. "
                                ++ "Я рассказываю о программировании и иногда о своей жизни."
                            })
                makeItem ""
                    >>= loadAndApplyTemplate indexTemplateName postsCtx
            else do
                posts <- recentFirst =<< loadAllSnapshots ids "content"
                let postsCtx =
                        listField "posts" postWithCommentsCountCtx (return posts) `mappend`
                        paginateContext paginate `mappend`
                        pageCtx (defaultMetadata
                            { metaTitle = Just $ show page ++ "-я страница"
                            , metaDescription = "Мой персональный блог, записи с " ++ show ((page - 1) * 5 + 1)
                                ++ " по " ++ show (page * 5) ++ "."
                            , metaUrl = "/page/" ++ show page ++ "/"
                            })
                makeItem ""
                    >>= loadAndApplyTemplate listTemplateName postsCtx

--------------------------------------------------------------------------------
-- Tags
--------------------------------------------------------------------------------

tagsPagesRules :: Rules ()
tagsPagesRules = do
    metadata <- getAllMetadata "post/**"
    let idents = fst $ unzip $ filter filterFn metadata
    tags <- buildTagsWith getTags (fromList idents) (\tag -> fromFilePath $ "tag/" ++ tag ++ "/index.html")
    d <- makePatternDependency "post/**"
    rulesExtraDependencies [d] $ create ["tags/index.html"] $ do
        route idRoute
        compile $ do
            t <- renderTags
                (\tag _ count minCount maxCount ->
                    "<a href=\"/tag/" ++ tag ++ "/\" title=\"" ++ countText count "пост" "поста" "постов" ++
                    "\" class=\"weight-" ++ show (getWeight minCount maxCount count) ++ "\">" ++ tag ++ "</a>")
                unwords tags
            let ctx = pageCtx (defaultMetadata
                    { metaTitle = Just "Темы"
                    , metaDescription = "Полный список тем (тегов) на сайте"
                    , metaUrl = "/tags/"
                    })
            makeItem t
                >>= loadAndApplyTemplate "templates/_tags-wrapper.html" ctx
                >>= loadAndApplyTemplate "templates/_post-without-footer.html" ctx
                >>= loadAndApplyTemplate defaultTemplateName ctx

    rulesExtraDependencies [d] $ tagsRules tags $ \tag identifiers -> do
        paginate <- buildPaginateWith 5 (getTagIdentifier tag) identifiers
        paginateRules paginate $ \page ids -> do
            route addIndexRoute
            compile $ do
                posts <- recentFirst =<< loadAllSnapshots ids "content"
                let postsCtx =
                        listField "posts" postWithCommentsCountCtx (return posts) `mappend`
                        paginateContext paginate `mappend`
                        pageCtx (defaultMetadata
                            { metaTitle = Just $ "\"" ++ tag ++
                                (if page == 1 then "\""
                                    else "\", " ++ show page ++ "-я страница")
                            , metaDescription = "Мой персональный блог, записи с тегом \"" ++ tag ++
                                (if page == 1 then "\"."
                                    else "\" с " ++ show ((page - 1) * 5 + 1) ++ " по " ++ show (page * 5) ++ ".")
                            , metaUrl = "/tag/" ++ tag ++
                                (if page == 1 then "/"
                                    else "/page/" ++ show page ++ "/")
                            })

                makeItem ""
                    >>= loadAndApplyTemplate listTemplateName postsCtx
    where
        filterFn :: (a, Metadata) -> Bool
        filterFn (_, metadata)
            | M.lookup "published" metadata == Just "false" = False
            | otherwise = True


getTags :: MonadMetadata m => Identifier -> m [String]
getTags identifier = do
    metadata <- getMetadata identifier
    return $ maybe [] (map trim . splitAll "," . unwrap) $ M.lookup "tags" metadata

--------------------------------------------------------------------------------
-- Static pages
--------------------------------------------------------------------------------

staticPagesRules :: Rules ()
staticPagesRules = do
    match (fromList ["about.md", "404.md"]) $ do
        route removeExtension
        compile $ do
            identifier <- getUnderlying
            title <- getMetadataField identifier "title"
            description <- getMetadataField identifier "description"
            pandocCompiler
                >>= loadAndApplyTemplate "templates/_post-without-footer.html" postCtx
                >>= loadAndApplyTemplate defaultTemplateName (pageCtx (defaultMetadata
                    { metaTitle = fmap unwrap title
                    , metaDescription = unwrap $ fromMaybe "" description
                    , metaUrl = '/' : identifierToUrl (toFilePath identifier)
                    }))

    match "shoutbox.md" $ do
        route removeExtension
        compile $ do
            identifier <- getUnderlying
            -- Comments
            thread <- getMetadataField identifier "thread"
            comments <- getComments thread
            -- Metadata
            title <- getMetadataField identifier "title"
            description <- getMetadataField identifier "description"
            pandocCompiler
                >>= loadAndApplyTemplate "templates/_post-shoutbox.html"
                    (constField "disqus" "shoutbox" `mappend`
                    commentsField comments `mappend`
                    postCtx)
                >>= loadAndApplyTemplate defaultTemplateName (pageCtx (defaultMetadata
                    { metaTitle = fmap unwrap title
                    , metaDescription = unwrap $ fromMaybe "" description
                    , metaUrl = '/' : identifierToUrl (toFilePath identifier)
                    }))

--------------------------------------------------------------------------------
-- Sitemap
--------------------------------------------------------------------------------

data SitemapItem = SitemapItem
    { siUrl :: String
    , siPriority :: String
    }

sitemapRules :: Rules ()
sitemapRules = do
    d <- makePatternDependency "post/**"
    rulesExtraDependencies [d] $ create ["sitemap.xml"] $ do
        route idRoute

        ids <- getMatches "post/**"
        let
            postItems = map (\i -> SitemapItem ("http://dikmax.name/" ++ identifierToUrl (toFilePath i)) "1.0") ids
        compile $
            makeItem ""
                 >>= loadAndApplyTemplate "templates/sitemap.xml" (sitemapField (staticItems ++ postItems))
    where
        staticItems =
            [ SitemapItem "http://dikmax.name/" "0.5"
            , SitemapItem "http://dikmax.name/about/" "0.8"
            , SitemapItem "http://dikmax.name/shoutbox/" "0.5"
            ]

sitemapField :: [SitemapItem] -> Context String
sitemapField items =
    constField "sitemap" $ concatMap sitemap items
    where
        sitemap (SitemapItem url priority) = "<url><loc>" ++ url ++
            "</loc><changefreq>daily</changefreq><priority>" ++ priority ++ "</priority></url>\n"


--------------------------------------------------------------------------------
-- Contexts
--------------------------------------------------------------------------------

timeLocale :: TimeLocale
timeLocale = defaultTimeLocale
  { wDays =
    [ ("Воскресенье", "вс")
    , ("Понедельник", "пн")
    , ("Вторник", "вт")
    , ("Среда", "ср")
    , ("Четверг", "чт")
    , ("Пятница", "пт")
    , ("Суббота", "сб")
    ]
  , months =
    [ ("января", "янв")
    , ("февраля", "фев")
    , ("марта", "мар")
    , ("апреля", "апр")
    , ("мая", "май")
    , ("июня", "июн")
    , ("июля", "июл")
    , ("августа", "авг")
    , ("сентября", "сен")
    , ("октября", "окт")
    , ("ноября", "ноя")
    , ("декабря", "дек")
    ]
  }

tagsContext :: Context a
tagsContext = field "tags" convertTags
    where
        convertTags item = do
            tags <- getTags $ itemIdentifier item
            return $ concatMap (\tag -> "<a href=\"/tag/" ++ tag ++ "/\" class=\"label label-default\">" ++ tag ++ "</a> ") tags

postCtx :: Context String
postCtx =
    dateFieldWith timeLocale "date" "%A, %e %B %Y, %R" `mappend`
    dateFieldWith defaultTimeLocale "post-date" "%Y-%m-%dT%H:%M:%S%z" `mappend`
    field "url" (return . identifierToUrl . toFilePath . itemIdentifier) `mappend`
    field "disqus" (return . identifierToDisqus . toFilePath . itemIdentifier) `mappend`
    field "title" (\i -> do
      metadata <- getMetadata $ itemIdentifier i
      return $ escapeHtml $ maybe "" unwrap $ M.lookup "title" metadata) `mappend`
    tagsContext `mappend`
    defaultContext

postWithCommentsCountCtx :: Context String
postWithCommentsCountCtx =
    constField "commentsCount" "" `mappend`
    postCtx

pageCtx :: PageMetadata -> Context String
pageCtx (PageMetadata title url description keywords fType)=
    constField "meta.title" (escapeHtml $ metaTitle title) `mappend`
    constField "meta.url" (escapeHtml $ "http://dikmax.name" ++ url) `mappend`
    constField "meta.description" (escapeHtml description) `mappend`
    constField "meta.keywords" (escapeHtml $ intercalate ", " keywords) `mappend`
    constField "meta.dc.subject" (escapeHtml $ intercalate "; " keywords) `mappend`
    facebookFields fType `mappend`
    defaultContext
    where
        metaTitle Nothing = "[dikmax's blog]"
        metaTitle (Just title) = title ++ " :: [dikmax's blog]"

        facebookFields (FacebookArticle published keywords images) =
                constField "meta.facebook.article" "" `mappend`
                constField "meta.facebook.published" (formatTime defaultTimeLocale "%Y-%m-%dT%H:%M:%SZ" published) `mappend`
                listField "meta.facebook.tags" defaultContext (mapM makeItem keywords) `mappend`
                listField "meta.facebook.images" defaultContext (mapM makeItem images)
        -- TODO Facebook profile
        facebookFields _ = constField "meta.facebook.nothing" ""

--------------------------------------------------------------------------------
-- Html metadata
--------------------------------------------------------------------------------

data FacebookType = FacebookBlog
    | FacebookArticle UTCTime [String] [String] -- Published, keywords, images
    | FacebookProfile
    | FacebookNothing

data PageMetadata = PageMetadata
    { metaTitle :: Maybe String
    , metaUrl :: String
    , metaDescription :: String
    , metaKeywords :: [String]
    , metaType :: FacebookType
    }

defaultMetadata :: PageMetadata
defaultMetadata = PageMetadata
    { metaTitle = Nothing
    , metaUrl = "/"
    , metaDescription = ""
    , metaKeywords = ["Blog", "блог"]
    , metaType = FacebookNothing
    }


--------------------------------------------------------------------------------
-- Replacement of Hakyll functions
--------------------------------------------------------------------------------

buildPaginateWith :: MonadMetadata m
                  => Int
                  -> (PageNumber -> Identifier)
                  -> Pattern
                  -> m Paginate
buildPaginateWith n makeId pattern = do
    metadata <- getAllMetadata pattern
    let idents         = fst $ unzip $ sortBy compareFn $ filter filterFn metadata
        pages          = flip unfoldr idents $ \xs ->
            if null xs then Nothing else Just (splitAt n xs)
        nPages         = length pages
        paginatePages' = zip [1..] pages
        pagPlaces'     =
            [(ident, idx) | (idx,ids) <- paginatePages', ident <- ids] ++
            [(makeId i, i) | i <- [1 .. nPages]]

    return $ Paginate (M.fromList paginatePages') (M.fromList pagPlaces') makeId
        (PatternDependency pattern idents)

    where
        compareFn :: (a, Metadata) -> (a, Metadata) -> Ordering
        compareFn (_, a) (_, b)
            | isNothing (M.lookup "date" a) && isNothing (M.lookup "date" b) = EQ
            | isNothing (M.lookup "date" a) = GT
            | isNothing (M.lookup "date" b) = LT
            | otherwise = compare (unwrap $ b M.! "date") (unwrap $ a M.! "date")
        filterFn :: (a, Metadata) -> Bool
        filterFn (_, metadata)
            | M.lookup "published" metadata == Just "false" = False
            | otherwise = True


-- | Takes first, current, last page and produces index of next page
type RelPage = PageNumber -> PageNumber -> PageNumber -> Maybe PageNumber

paginateField :: Paginate -> String -> RelPage -> Context a
paginateField pag fieldName relPage = field fieldName $ \item ->
    let identifier = itemIdentifier item
    in case M.lookup identifier (paginatePlaces pag) of
        Nothing -> fail $ printf
            "Hakyll.Web.Paginate: there is no page %s in paginator map."
            (show identifier)
        Just pos -> case relPage 1 pos nPages of
            Nothing   -> fail "Hakyll.Web.Paginate: No page here."
            Just pos' -> do
                let nextId = paginateMakeId pag pos'
                mroute <- getRoute nextId
                case mroute of
                    Nothing -> fail $ printf
                        "Hakyll.Web.Paginate: unable to get route for %s."
                        (show nextId)
                    Just rt -> return $ removeIndex $ toUrl rt
  where
    nPages = M.size (paginatePages pag)
    removeIndex url
        | "index.html" `isSuffixOf` url = take (length url - 10) url
        | otherwise = url

paginateContext :: Paginate -> Context a
paginateContext pag = mconcat
    [ paginateField pag "firstPage"
        (\f c _ -> if c <= f then Nothing else Just f)
    , paginateField pag "previousPage"
        (\f c _ -> if c <= f then Nothing else Just (c - 1))
    , paginateField pag "nextPage"
        (\_ c l -> if c >= l then Nothing else Just (c + 1))
    , paginateField pag "lastPage"
        (\_ c l -> if c >= l then Nothing else Just l)
    ]

getItemUTC :: MonadMetadata m
           => TimeLocale        -- ^ Output time locale
           -> Identifier        -- ^ Input page
           -> m UTCTime         -- ^ Parsed UTCTime
getItemUTC locale id' = do
    metadata <- getMetadata id'
    let tryField k fmt = fmap unwrap (M.lookup k metadata) >>= parseTime' fmt
        fn             = takeFileName $ toFilePath id'

    maybe empty' return $ msum $
        [tryField "published" fmt | fmt <- formats] ++
        [tryField "date"      fmt | fmt <- formats] ++
        [parseTime' "%Y-%m-%d" $ intercalate "-" $ take 3 $ splitAll "-" fn]
  where
    empty'     = fail $ "Hakyll.Web.Template.Context.getItemUTC: " ++
        "could not parse time for " ++ show id'
    parseTime' = parseTime locale
    formats    =
        [ "%a, %d %b %Y %H:%M:%S %Z"
        , "%Y-%m-%dT%H:%M:%S%Z"
        , "%Y-%m-%d %H:%M:%S%Z"
        , "%Y-%m-%dT%H:%M%Z"
        , "%Y-%m-%d %H:%M%Z"
        , "%Y-%m-%d"
        , "%B %e, %Y %l:%M %p"
        , "%B %e, %Y"
        , "%b %d, %Y"
        ]


dateFieldWith :: TimeLocale  -- ^ Output time locale
              -> String      -- ^ Destination key
              -> String      -- ^ Format to use on the date
              -> Context a   -- ^ Resulting context
dateFieldWith locale key format = field key $ \i -> do
    time <- getItemUTC locale $ itemIdentifier i
    return $ formatTime locale format time

pandocCompiler :: Compiler (Item String)
pandocCompiler = do
    post <- getResourceBody
    makeItem $ T.unpack $ T.decodeUtf8 $ toByteString $ renderHtmlFragment UTF8 $ writeXmlHtml defaultXmlHtmlWriterOptions
        { idPrefix = "" --postUrl post
        , debugOutput = False
        }
        (readMarkdown readerOptions $ itemBody post)

readerOptions :: ReaderOptions
readerOptions = def
  { readerSmart = True
  , readerParseRaw = True
  }

--------------------------------------------------------------------------------
-- | Sort pages chronologically. Uses the same method as 'dateField' for
-- extracting the date.
chronological :: MonadMetadata m => [Item a] -> m [Item a]
chronological =
    sortByM $ getItemUTC defaultTimeLocale . itemIdentifier
  where
    sortByM :: (Monad m, Ord k) => (a -> m k) -> [a] -> m [a]
    sortByM f xs = liftM (map fst . sortBy (comparing snd)) $
                   mapM (\x -> liftM (x,) (f x)) xs

--------------------------------------------------------------------------------
-- | The reverse of 'chronological'
recentFirst :: (MonadMetadata m, Functor m) => [Item a] -> m [Item a]
recentFirst = fmap reverse . chronological

--------------------------------------------------------------------------------
-- Utility functions
--------------------------------------------------------------------------------

unwrap :: String -> String
unwrap str -- TODO decode escaped chars
    | str == "\"" || str == "" = str
    | head str == '"' && last str == '"' = tail $ init str
    | otherwise = str

-- Replace newlines with spaces
transformDescription :: String -> String
transformDescription = map (\ch -> if ch == '\n' then ' ' else ch)

-- Cut long descriptions
cutDescription :: String -> String
cutDescription d
    | length d > 512 = reverse (dropWhile isSpace $ dropWhile (not . isSpace) $ reverse $ take 512 d) ++ "..."
    | otherwise = d

getTagIdentifier :: String -> PageNumber -> Identifier
getTagIdentifier tag pageNum
    | pageNum == 1 = fromFilePath $ "tag/" ++ tag ++ "/"
    | otherwise = fromFilePath $ "tag/" ++ tag ++ "/page/" ++ show pageNum ++ "/"

getPageIdentifier :: PageNumber -> Identifier
getPageIdentifier pageNum
    | pageNum == 1 = fromFilePath ""
    | otherwise = fromFilePath $ "page/" ++ show pageNum ++ "/"

addIndexRoute :: Routes
addIndexRoute = customRoute (\id ->
    if toFilePath id == ""
        then "index.html"
        else toFilePath id ++ "/index.html")

-- | Transforms 'something/something.md' into 'something/something/index.html'
-- and 'something/YYYY-MM-DD-something.md' into 'something/something/index.html'
removeExtension :: Routes
removeExtension = customRoute $ removeExtension' . toFilePath

removeExtension' :: String -> String
removeExtension' filepath = subRegex (mkRegex "^(.*)\\.md$")
                                        (subRegex (mkRegex "/[0-9]{4}-[0-9]{2}-[0-9]{2}-(.*)\\.md$") filepath "/\\1/index.html")
                                        "\\1/index.html"

identifierToUrl :: String -> String
identifierToUrl filepath = subRegex (mkRegex "^(.*)\\.md$")
                                        (subRegex (mkRegex "/[0-9]{4}-[0-9]{2}-[0-9]{2}-(.*)\\.md$") filepath "/\\1/")
                                        "\\1/"

identifierToDisqus :: String -> String
identifierToDisqus filepath = subRegex (mkRegex "^post/[0-9]{4}-[0-9]{2}-[0-9]{2}-(.*)\\.md$") filepath  "\\1"

countText :: Int -> String -> String -> String -> String
countText count one two many
    | count `mod` 100 `div` 10 == 1 =
        show count ++ " " ++ many
    | count `mod` 10 == 1 =
        show count ++ " " ++ one
    | (count `mod` 10) `elem` [2, 3, 4] =
        show count ++ " " ++ two
    | otherwise =
        show count ++ " " ++ many


getWeight :: Int -> Int -> Int -> Int
getWeight minCount maxCount count =
    round ((5 * ((fromIntegral count :: Double) - fromIntegral minCount) +
        fromIntegral maxCount - fromIntegral minCount) /
        (fromIntegral maxCount - fromIntegral minCount))

