#!/bin/bash
for i in {1..3}; do
    STUDENT_NUM=$(printf "%02d" $i)
    STUDENT_BRANCH="student${STUDENT_NUM}"
    echo "DEBUG: i=$i, STUDENT_NUM=$STUDENT_NUM, STUDENT_BRANCH=$STUDENT_BRANCH"
    echo "Would run: git checkout -b \"$STUDENT_BRANCH\" main"
done
