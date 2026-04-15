#!/bin/bash

files=$(find data/*)

echo '================================================================================'
echo 'load denormalized'
echo '================================================================================'
time for file in $files; do
    unzip -p "$file" \
        | python3 -c 'import sys,csv; w=csv.writer(sys.stdout); [w.writerow([line.rstrip("\n").replace("\x00","").replace("\\u0000","")]) for line in sys.stdin]' \
        | psql -v ON_ERROR_STOP=1 postgresql://postgres:pass@localhost:10930/postgres \
          -c "\copy tweets_jsonb(data) FROM STDIN WITH (FORMAT csv)"
done

echo '================================================================================'
echo 'load pg_normalized'
echo '================================================================================'
time for file in $files; do
    python3 load_tweets.py \
        --db=postgresql://postgres:pass@localhost:10931/postgres \
        --inputs "$file"
done

echo '================================================================================'
echo 'load pg_normalized_batch'
echo '================================================================================'
time for file in $files; do
    python3 -u load_tweets_batch.py --db=postgresql://postgres:pass@localhost:10932/ --inputs $file
done
