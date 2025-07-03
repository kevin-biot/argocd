# Delete all the old incorrectly named LOCAL branches
for i in {1..25}; do
    echo "Deleting local branch student$i..."
    git branch -D student$i 2>/dev/null || true
done

