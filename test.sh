# Test the logic manually
for i in {1..3}; do
    STUDENT_NUM=$(printf "%02d" $i)
    STUDENT_BRANCH="student${STUDENT_NUM}"
    echo "i=$i, STUDENT_NUM=$STUDENT_NUM, STUDENT_BRANCH=$STUDENT_BRANCH"
done
