#!/bin/bash

#Reguirements:
#  - must run on ceph admin

#Limitations:
#  - Assumes same OSD# for all pools

#POOL_DETAIL=$(ceph osd pool ls detail 2> /dev/null )
#DF=$(ceph df 2> /dev/null )
#NUM_OSD=$(ceph osd ls 2> /dev/null | wc -l)
POOL_DETAIL=$(docker exec ceph-mon-Ceph-1 ceph osd pool ls detail 2> /dev/null)
DF=$(docker exec ceph-mon-Ceph-1 ceph df 2> /dev/null)
NUM_OSD=$(docker exec ceph-mon-Ceph-1 ceph osd ls 2> /dev/null | wc -l)

FORMAT="%-15s %8s %8s %8s %8s %8s %11s %11s %8s\n"
printf "$FORMAT" "POOL" "SIZE" "OSD#" "%DATA" "PG(100)" "PG(200)" "PG(100@80%)" "PG(200@80%)" "PG(NOW)"
printf "$FORMAT" | tr ' ' -

power2() {
        if [ $1 -lt 1 ]; then echo 2; return; fi
        x=`echo | awk -v a="$1" '{print int(((a/2)+0.5)/1)}'`
        echo $x
}

pgcalc(){
        TARGET_POOL="$1"
        SIZE=$(echo -n "$POOL_DETAIL" | grep $TARGET_POOL | awk '{print int($6+0.0)}')
        PG_NOW=$(echo -n "$POOL_DETAIL" | grep $TARGET_POOL | awk '{print int($16+0.0)}')
        PCT_DATA=$(echo -n "$DF" | grep $TARGET_POOL | awk '{printf "%.2f",$4}')

        if [ $SIZE == 0 ]; then
                return;
        fi

        #echo $SIZE
        #echo $PG_NOW
        #echo $PCT_DATA
        #echo "========"
        #echo "NUM_OSD="$NUM_OSD
        #NUM_OSD_INT=$((10#${NUM_OSD}))

        PG_100_TMP=`echo | awk -v o="$NUM_OSD" -v d="$PCT_DATA" -v s="$SIZE" '{print int((100*o*d*0.01)/s)}'`
        PG_100_80_PCT_TMP=`echo | awk -v o="$NUM_OSD" -v s="$SIZE" '{print int((100*o*80*0.01)/s)}'`
        PG_200_TMP=`echo | awk -v o="$NUM_OSD" -v d="$PCT_DATA" -v s="$SIZE" '{print int((200*o*d*0.01)/s)}'`
        PG_200_80_PCT_TMP=`echo | awk -v o="$NUM_OSD" -v s="$SIZE" '{print int((200*o*80*0.01)/s)}'`
        echo "========"
        #echo "PG_100_TMP="$PG_100_TMP
        #echo $PG_100_80_PCT_TMP
        #echo $PG_200_TMP
        #echo $PG_200_80_PCT_TMP

        PG_100="$(power2 $PG_100_TMP)"
        PG_100_80_PCT=$(power2 $PG_100_80_PCT_TMP)
        PG_200=$(power2 $PG_200_TMP)
        PG_200_80_PCT=$(power2 $PG_200_80_PCT_TMP)

        #PG_100="$(power2 $(echo "(100 * $NUM_OSD * $PCT_DATA*0.01) / $SIZE" | bc))"
        #PG_100_80_PCT=$(power2 $(echo "(100 * $NUM_OSD * 80*0.01) / $SIZE" | bc))
        #PG_200=$(power2 $(echo "(200 * $NUM_OSD * $PCT_DATA*0.01) / $SIZE" | bc))
        #PG_200_80_PCT=$(power2 $(echo "(200 * $NUM_OSD * 80*0.01) / $SIZE" | bc))

        printf "$FORMAT" "$TARGET_POOL" "$SIZE" "$NUM_OSD" "$PCT_DATA" "$PG_100" "$PG_200" "$PG_100_80_PCT" "$PG_200_80_PCT" "$PG_NOW"
}

POOL_NAMES=$(echo -n "$POOL_DETAIL" | awk '{print $3}' | tr -d \' | tr '\n' ' ' | sed 's/[ ][ ]*/ /g')
for pool in $POOL_NAMES
do
        pgcalc $pool
done

