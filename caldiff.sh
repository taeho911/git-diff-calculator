#!/bin/bash

branch=$1
[ -z $branch ] && branch="HEAD"
report=report.txt
[ -f $report ] && rm -f $report
base_regex="master/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]"
base_tag=$(git tag -l $base_regex --no-contains $branch | sort -V | tail -1)

declare -a merge_commits
declare -a branch_commits
merge_commits=($(git rev-list --reverse --first-parent --merges $base_tag..$(git rev-parse $branch)))
branch_commits=($(git rev-list --reverse --first-parent $base_tag..$(git rev-parse $branch)))

length_mc=${#merge_commits[*]}
length_bc=${#branch_commits[*]}

m_i=0

echo "length_mc=$length_mc, length_bc=$length_bc"

for (( b_i=0; b_i<$length_bc; b_i++ ))
do
    echo "b_i=$b_i, m_i=$m_i"
    if [ $b_i -eq 0 ]
    then
        pre=$base_tag && continue
    elif [ ${branch_commits[$b_i]} == ${merge_commits[$m_i]} ]
    then
        post=${branch_commits[$((b_i-1))]}
        echo "pre=$pre, post=$post"
        git diff --numstat $pre $post >> $report
        pre=${merge_commits[$m_i]}
        m_i=$((m_i+1))
        continue
    elif [ $b_i -eq $((length_bc-1)) ]
    then
        post=${branch_commits[$b_i]}
        echo "pre=$pre, post=$post"
        git diff --numstat $pre $post >> $report
        echo "The End"
    fi
done

exit 0