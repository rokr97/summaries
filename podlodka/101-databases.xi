Podlodka #101: Базы данных ft. Николай Голов (Авито)  .
OLTP - найти дерево в лесу, найти пост в фейсбуке и поменять. Простой insert/update, update должен быть крутой 

OLAP - посмотреть на лес, пощитать аггрегации. Select, count, group by. Update или запрещен, или плохо работает

One-size fits all подходит для инет-магазов

OLTP-first базы (оракл, постгре) плохо справляются с постоянной аналитической нагрузкой (olap). Например, когда юзеры магаза хотят посмотреть средний спрос на товары. count(*) - легкий, дистинкты с груп баями и оконные функции - тяжелые.
Это из-за организации хранения - row storage. Для аггрегации приходится поднимать все строки в память.

Колоночные базы ту зе рескью: храним отдельной колонкой остатки по счетам и тогда нам достаточно поднять ток её и просуммировать. В аналитических базах бывает до 100 колонок. Штоп выбрать строку, надо все их поднять и склеить. Это можно сделать очень эффективно: стичинг (то как ширинка застегивается) - это когда строка сшивается сразу при чтении колонок с диска. Пайплайн: сшил строку - скинул.
Скорость записи решена батчами.
Удаление - поднять всю колонку и перезаписать.
Делаем задание на delete, строка помечается и при чтении скипается, а потом в фоне удаляется, потому что запись блоками. Блоки по 200МБ. Поэтому работают одинаково на ssd и sas-дисках. 
Хранят сотни миллиардов строк, где count(*) отрабатывает за секунды. Поддерживают обычный sql, только Апдейты работают медленно. 

Hadoop говно, спарк нужен для 1% случаев, когда пихдата не влезает в 512 ГБ RAM. 

Колоночные базы горизонтально масштабируемы. Хорошо размазываются на кольцо серверов. 
В кликхаузе двойное кольцо. Штоп не дублировать физически, делают такое: при шардировании строка идет на id = mod (hash / server count) и на id+1.
Нельзя покарраптить данные потому, что запись считается успешной, если записалось на обе ноды. 


Проблема OLTP-баз решаются кэшом, тк сначала кончается IOPS, потом память. Так что сначала кэш, потом кэш и базу разнести на разные серваки, потом Redis в качестве кэша. Рэдис хорошо шардируется. Например, 10 серверов с редисом и 1 сервер с бд. 

Колоночные базы рвут всех с запасом: clickhouse, green plan, Vertica.
Vertica is a write-optimized storage.

Hadoop is map-reduce based. Гугл отказался от мап редьюс в 2014 году. Не взлетело потому, что нельзя обращаться из sql.

Авито юзает кликхауз для логов: 4 млн записей в секунду


VoltDB - оч производительный. Аналог - tarantool от mail.ru. Минусы - все на хранимых процедурах.

Саги:
Где помогают: есть биллинг, есть система, хранящая подключённые услуги. Нужно убедиться, что деньги списались, услуги подключились. 

Метафора саги: 
произошло событие (битва, свадьба) и пошли  новости: кто-то поскакал, кто-то послал ворона, кто-то поплыл на корабле. В итоге какой-то человек получает весть и тоже посылает гонца. В итоге по миру растекаются гонцы, вороны, люди что-то делают. И в мире логических противоречий не происходит. Бывает, что человек получает новость о событии значительно позже, чем он должен был, и поэтому ведет себя неправильно. Но это, наоборот, добавляет сюжету интереса. 
Суть саги в эмулировании данной ситуации:
Вышло войско, тут должна была быть свадьба, но прилетели драконы. 
1) Нужно, чтобы каждый элемент системы привык жить без контролирующего органа и просто реагировать на сигналы. 
2) Нужно, чтобы эти сигналы оставляли следы. Чтобы отправленное письмо не растворялось в воздухе. Даже если оно не дошло до получателя, чтобы кто-то его нашёл и потом довёз. 
3) Чтобы не было непоправимых событий (директивных апдейтов). Например, "теперь у юзера баланс 8 рублей". Что делать? Посылать ивенты вида "спиши 2 рубля". Или лучше: отложи два рубля, делаете другие проверки, потом говорите "отправь два рубля Семёнычу" 
Ещё пример: юзер покупает статус вип. И пока вы обрабатывали, купил ещё и супервип и оно успело быстрее обработаться. При директивном апдейте "сделай статус вип" клиент из супер-вип перейдет обратно в вип. 
Что делать? Кидать ивент вида "повысь статус на 1, но не выше вип".

Polyglot persistance: щотчики храни в редисе, посты в монге, фискальную инфу в постргесе (какие стикерпаки юзер покупал), а аналитику в реальном времени (штоп пощитать, какой баннер показать юзеру) - в тарантуле

Обычным базам не хватает горизонтальной масштабируемости. Cloud to the rescue.
Cloud Spanner от гугла (кросс-датацентровая): эластично горизонтально масштабируемая, консистентная, поддерживает SQL, игнорирует cap-теорему (unavailable на секунду в год). Запросы чуть подольше работают (до 100-200 мс) из-за маршрутизации.
Аналог - CockroachDB (но рядом не валялась)

Задача в наращивании мощностей, пофиг скока там реально серваков под базой. 
Snowflake написана над абстракцией хранилища типа amazon s3. Два кольца серверов: хранилища и считалища. Если пришло дофига запросов, то база подключает ещё считающих серверов на несколько минут и потом отключает. Она может очень быстро это делать, тк хранилище отдельно и не трогается

Почему базы данных плачут (Михаил Ярийчук) [#1] .
. Доклад от разработчика RavenDB о реальных проблемах эксплуатации реляционных и NoSQL баз данных, деталях архитектуры и реализации современных БД. В этом докладе Михаил расскажет о распространенных ошибках в работе с RDBMS и NoSQL базах данных, как они влияют на производительность, почему они происходят, и как уменьшить их эффект или вовсе предотвратить.
. |RavenDB (NoSQL)| - safe by default, optimized for efficiency. 

  1a. Storage .
    * Disk queue length should be monitored (disk queue length > 5 means that problems are coming)
    * Load test database-related code
      * `write-through` throughput
      * enough IOPS for expected production load (disk queue length <=2)
      * use CrystalDiskMark
        * Random/sequential I/O?
        * Queues/THreads (queue depth/length)
    * Cloud -> provision IOPS (ensure disk performance)

  1b. Primary keys .
  . In general sequential UUID keys are written faster than random ones. 
  . This is due to page-oriented storage engines
    * B-tree, B+ Tree
    * optimized for reads
    * optimized for sequential data
  . B-trees are used to store data AND indexes
    * Better query performance

  1c. Data structure performance .
  . Sometimes Cassandr read perfomance occasionally drops, and this happens non-deterministically.
  . This is due to log-structured merge tree storage algorithm.
    * Storage part is based on Sorted String Tables (SSTables), which uses hashes and strings as values
    * In-memory part is usually a B-Tree or Skip List
    * all data manipulation operations (create, update, delete) when flushed from memory are added to the end of the stored values in a new SSTable so `reading requires searching all SSTables`
  . LSM Tree compaction takes place to mitigate read speed decrease. This is roughly O(n*log(n)) operation! But usually such operation are executed asyncrously.
    Performance depends on compaction .
    . Compaction strategies -> WHEN compaction is triggered?
      * Leveled -> optimized for inserts
      * SizeTiered -> for reads
      * Time-window -> for time series / immutable data
    . |{lng:СQL}
      | ALTER TABLE users
      | WITH compaction = 
      | {'class' : 'SizeTieredCompactionStrategy', 'min_threshold : 6}
  
  . Different databases have specific options to optimize performance
    * MS-SQL index optimization
    * RavenDB custom indexes
    * MongoDB Aggregation Pipelines
  1d. Transaction implementation & performance .
    ACID .
    * |Atomicity| - all operations either succeed or not
    * |Consistency| - data is consistent before and after transaction
    * |Isolation| - multiple transactions do not interfere each other
    * |Durability| - even if system failure happens, transaction is recorded
  . Some of NoSQL support ACID - RavenDB, LevelDB, LMDB, MongoDB.
  . A+D is implemented with Write-Ahead Log (WAL).
  . Until commit is received all data is written in some mutable queue. When commin is received then the actual write happens and data is flushed to the storage.
    ATTO Disk benchmark .
    . It can test disks in a "bypass write cache" mode (write through).
    . Write-through is required for durability (otherwise data could by lost in disk cache on power failure).
    . No cache mode is 1000x slower that buffered one (MB/s vs GB/s)
      Storage effect on transactions .
        * slow storage throughput = bottleneck on transactions
        * write-through performance = transaction throughput
  
  Indexing & Queries .
    Query complexity .
    . In our example search by city in MongoDB resulted in index scan O(log(n)), but search by country used collection scan O(n).
    . In some databases (like MongoDB)
      * indexed fields are concateneted into single index key
      * filtering only by prefix
    . the values are concatenated vvv
      | field1 | field2     Index Key  | Record IDs
      | Lyon   | France     LyonFrance | 7, 1, 4
      | Paris  | France     ParisFrance| ...
      | Oslo   | Norway     OsloNorway | ...
    . In some other databases (RavenDB, any Lucene-based index)
      * indexed terms are stored separately
      * filtering by one or both fields in any order (union/intersect as needed)
    
    More about indexing .
      * indexes are stored as trees (usually B-trees)
      * updates have non-trivial complexity
    . RDBMS joins complexity
      * Merge join - O(n*log(n) + m*(log(m))
      * Hash join  - O(n+m)
      * Index join - O(m*log(n))
    
      What can (should!) we do? .
      . RDBS
        * proper indexing
        * optimize (remove unnecessary JOINs - depends on business logic)
        * reduce query complexity
          * replace 'row by row' cursors with set based queries
          * reduce the amount of work queries do (for example, unnecessary sub-queries)
          * remove order by where it makes sense (huge overhead)
          * other optimizations are possible
      . NoSQL
        * proper modeling
        * well planned indexing
    
    Indexes (sometimes) have complexity too .
    . Some databases have async indexing and when there are lots of indexes (more that 250 for the entire database) then it could lead to thread starvation.
  Network .
    Distributed system fallacies .
      Bandwidth is infinite .
      . Use server-side projections (NoSQL) to reduce the amount of data transferred to a client.
      Latency is zero .
      . Network overhead (round trip time - RTT)
        * physical distance (insignificant for LANs)
        * bandwidth
        * network hops
    
References .
[1#] [https://live.jugru.org/online/100064r10001864?p=sch100064]
