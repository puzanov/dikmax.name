---
title: "Парсер для CommonMark"
date: "2014-10-02T23:15:00+03:00"
published: true
collection: "md_proc"
tags: "commonmark, dart, markdown, md_proc, программирование"
---

![](/images/3rd-party/markdown-logo.png "Markdown logo")

Все началось с\ того, что мне понадобился парсер для Markdown, который строит [AST], а\ не\ пытается сразу выдавать 
готовый HTML. А\ ещё было желательно, чтобы парсер был написан на\ [Dart], так как проект я\ собирался писать именно 
на\ этом языке. Но, к\ сожалению, обнаружился только один парсер для Markdown, написанный на\ Dart. Поэтому идею 
пришлось отложить до\ лучших времён и\ сесть за\ написание своего ~~велосипеда~~ парсера.

Примерно через неделю после начала появилась спецификация [CommonMark], которая помогла избавиться от\ некоторых 
вопросов, правда ценой полного переписывания: некоторые концепции из\ спецификации никак не\ хотели ложиться на\ уже 
написанный код.

И\ вот, спустя месяц, я\ рад вам представить свою реализацию, которая проходит все тесты CommonMark. И\ да, она 
позволяет получить AST для последующей обработки.

Библиотека md_proc на [GitHub], [pub.dartlang][pub]. 

В\ самых ближайших планах реализовать восстановление Markdown обратно из\ AST, а\ также поддержка самых распространённых 
и\ нужных расширений, вроде TexMath, Footnotes, Smart punctuation и\ других. Ну\ и, конечно, поддержка совместимости 
с\ CommonMark тоже обязательно будет, тем более, что CommonMark ещё должен немного поменяться до\ того, как будет 
опубликована официальная версия 1.0. И\ уже после этого можно будет вернуться к\ первоначальному проекту.

[AST]: https://ru.wikipedia.org/wiki/%D0%90%D0%B1%D1%81%D1%82%D1%80%D0%B0%D0%BA%D1%82%D0%BD%D0%BE%D0%B5_%D1%81%D0%B8%D0%BD%D1%82%D0%B0%D0%BA%D1%81%D0%B8%D1%87%D0%B5%D1%81%D0%BA%D0%BE%D0%B5_%D0%B4%D0%B5%D1%80%D0%B5%D0%B2%D0%BE
[CommonMark]: http://commonmark.org/
[Dart]: https://www.dartlang.org/
[GitHub]: https://github.com/dikmax/md_proc
[pub]: https://pub.dartlang.org/packages/md_proc