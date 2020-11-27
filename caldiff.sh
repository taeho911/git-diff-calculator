#!/bin/bash

branch=$1
[ -z $branch ] && branch="HEAD"
numstat=numstat.txt
namestatus=namestatus.txt
combine=combine.txt
report=report.txt
[ -f $numstat ] && rm -f $numstat
[ -f $namestatus ] && rm -f $namestatus
[ -f $combine ] && rm -f $combine
[ -f $report ] && rm -f $report
base_regex="master/[0-9]{8}[^_]"
base_tag=$(git log --pretty=format:"%d" $branch -- | grep -oE "tag: $base_regex" | sed -e 's/tag: //' -e 's/.$//' | sort -V | tail -1)
# base_tag=$(git tag -l $base_regex --no-contains $branch | sort -V | tail -1)

echo "base_tag=$base_tag"

declare -a merge_commits
declare -a branch_commits
declare -a branch_commits_all
merge_commits=($(git rev-list --reverse --first-parent --merges $base_tag..$(git rev-parse $branch)))
branch_commits=($(git rev-list --reverse --first-parent $base_tag..$(git rev-parse $branch)))
branch_commits_all=($(git rev-list --first-parent $(git rev-parse $branch)))

length_mc=${#merge_commits[*]}
length_bc=${#branch_commits[*]}
real_base=${branch_commits_all[$length_bc]}

m_i=0

echo "length_mc=$length_mc, length_bc=$length_bc"

for (( b_i=0; b_i<$length_bc; b_i++ ))
do
    echo "b_i=$b_i, m_i=$m_i"
    if [ $b_i -eq 0 ]
    then
        pre=$real_base
        continue
    elif [ "${branch_commits[$b_i]}" == "${merge_commits[$m_i]}" ]
    then
        post=${branch_commits[$((b_i-1))]}
        echo "pre=$pre, post=$post"
        git diff --numstat $pre $post >> $numstat
        git diff --name-status $pre $post >> $namestatus
        pre=${merge_commits[$m_i]}
        m_i=$((m_i+1))
        continue
    elif [ $b_i -eq $((length_bc-1)) ]
    then
        post=${branch_commits[$b_i]}
        echo "pre=$pre, post=$post"
        git diff --numstat $pre $post >> $numstat
        git diff --name-status $pre $post >> $namestatus
        echo "The End"
        echo
    fi
done

awk 'FNR==NR {arr[FNR]=FNR"__"$1; next} {print arr[FNR]"__"$1"__"$2"__"$3}' $namestatus $numstat > $combine

declare -a combine_arr
declare -A report_arr
combine_arr=($(cat $combine))
length_ca=${#combine_arr[*]}

for (( i=0; i<$length_ca; i++ ))
do
    key=$(echo ${combine_arr[$i]} | awk -F__ '{print $NF}')
    echo "key=$key, ${report_arr["$key"]}"
    if [ ! -z "${report_arr[$key]}" ]
    then
        declare -a temparr
        temparr=($(echo ${combine_arr[$i]} | sed 's/__/ /g'))
    elif [ -z "${report_arr[$key]}" ]
    then
        report_arr["$key"]=${combine_arr[$i]}
        echo "report_arr added :: ${report_arr["$key"]}"
    fi
done

exit 0