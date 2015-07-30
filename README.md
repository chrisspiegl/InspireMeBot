# InspireMeBot

InspireMeBot will give you inspiring quotes on a daily basis. It is easy and uplifting!

You can add this bot via this link: https://telegram.me/InspireMeBot

And please think about rating the bot via: https://telegram.me/storebot?start=InspireMeBot

## Quote Database

The quote database soemthing I am not going to include in this repository since it is just too big. I downloaded it from http://thewebminer.com/download.

The quote databse is stored in `/storage/quotes_all.csv` and the format is:
```
QUOTE;AUTHOR;GENRE
```

## Notes

### Uberspace SQLite Problem

Sqlite needs some special attention on Uberspace servers. [Source](https://wiki.uberspace.de/development:nodejs#sqlite3)

Put the following into the `.bashrc` or `.zshrc`

```
export TMPDIR=`mktemp -d /tmp/XXXXXX`
```

and install sqlite3 via:

```
npm install sqlite3 --build-from-source
```
