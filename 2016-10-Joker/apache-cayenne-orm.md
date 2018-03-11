# Apache Cayenne ORM

[Андрусь Адамчик @ Joker 2016](https://www.youtube.com/watch?v=yfCNVMSVYLk)

* есть маппинг-тула, генерящая по базе xml'ку и классы
* по xml'ке создается синглтон ServerRuntime
* сгенеренные классы живут отдельно от вашего кода
* был пример, как автогенерить схему и классы через maven-goal. Андрусь рекомендует использовать какой-то профиль для генерации схемы (т.к. лезет в базу), а cgen (class generator) можно и при каждой компиляции гонять
* селекты составляются как в SQL-виде, так и JOOQ-style (чтобы можно было рефакторить).
* был показан prefetch данных через join для query. Подцепили все Paintings к запросу Artists.EXHIBITIONS.dot.like(%museum%)

В коде данные создаются через `runtime.getContext.newObject(T.class)`.  
Сохраняются через `context.commit()` (или save?)

Рантайм создается через билдер. Если в мапинг-туле создать `dataNode`, то сгенеренная `xml`'ка будет содержать данные коннекта и рантайму кроме имени xml-маппинга ничо не надо.

## Преимущества
- не держит постоянного коннекта в базу (и вообще никаких ресурсов), т.к. рантайм-объект просто висит в памяти и ходит в базу только когда надо.
- по-дефолту транзакции implicit (но есть API и для ручного управления, если понадобится)
- генерит удобочитаемые SQL

## 2-Way encryption
- добавляется зависимость в pom: cayenne-crypto
- по конвеншну кайена в базе колонка для шифрования использует префикс CRYPTO_
- в мапинг туле можно указать имя проперти класса без crypto
- crypto создается как модуль с указанием кейстора, пароля и ключа. Пароль в виде CharArray (нельзя прочитать дампом памяти)
- модуль подключается к рантайму
- профит! (в логах видны только шифрованные значения)

## Еще фичи
- Module myExtension = (binder) -> binder.bind(Query.class).to.(EhCacheQueryCache.class) - подключение кэша
- ObjectSelect.query(Artists.class).localCache("artists").select(context) - использование
- Streaming API to handle large result sets: ObjectSelect.query(Artist.class).iterate(context, artist -> sout.(artist.getName()). Еще есть batchIterator.

## Why Cayenne?
- Mature (developed since 2002), performant, user friendly
- The only* ORM alternative to JPA/Hibernate (* по версии лида проекта кайен)
- Implicit transactions and smooth object graph navigation
- Comminity-driven, you have a voice!

## Q&A
**Есть ли тулза миграции с JPA на Cayenne?**  
Самое простое - это сгенерить по схеме БД. А дальше уже свой код ручками, адаптировать, да.

**Можно ли в маппинге фильтровать таблицы и т.п.?**  
Да, в 4-й версии можно и схемы, и таблицы, и колонки фильтровать.
Андрусь рекомендовал юзать v4 даже на стадии альфа и даже nightly build, так как хорошее покрытие тестами и всё такое.

**Какая совместимость с Jackson?**  
Андрусь на докладе про Bootique показывал тул link-rest, который примерно так и мапит от слоя ORM до слоя REST API. link-rest понимает модель Cayenne вообще без настроек.

@ApacheCayenne  
http://cayenne.apache.org  
https://github.com/apache/cayenne
