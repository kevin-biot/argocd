#!/bin/bash
# ------------------------------------------------------------------
# Update all student branches with latest changes from main
# Run this after making changes to main branch
# ------------------------------------------------------------------
set -euo pipefail

echo "🔄 Updating Student Branches with Latest Main Branch Changes"
echo "============================================================"

# Ensure we're in a git repository
if [[ ! -d .git ]]; then
    echo "❌ Error: Not in a git repository root directory"
    echo "   Please run this script from your argocd repository root"
    exit 1
fi

# Make sure we have the latest main branch
echo "📥 Fetching latest changes from remote..."
git fetch origin

# Switch to main and ensure it's up to date
echo "🔄 Switching to main branch..."
git checkout main
git pull origin main

echo ""
echo "📋 This will update all 25 student branches with latest main branch changes"
echo "   Each branch will be reset to match main and force-pushed to origin"
echo "⚠️  WARNING: This will overwrite any student changes in their branches!"
read -rp "❓ Proceed with branch updates? (y/n): " CONFIRM
[[ "$CONFIRM" != [yY] ]] && { echo "❌ Aborted."; exit 1; }

echo ""
echo "🚀 Updating student branches..."

# Update all 25 branches
UPDATED_COUNT=0
for i in {1..25}; do
    # Format with leading zero
    STUDENT_NUM=$(printf "%02d" $i)
    STUDENT_BRANCH="student${STUDENT_NUM}"
    echo -n "   Updating $STUDENT_BRANCH... "
    
    # Switch to student branch (create if it doesn't exist)
    if git branch --list | grep -q "$STUDENT_BRANCH"; then
        git checkout "$STUDENT_BRANCH"
    else
        git checkout -b "$STUDENT_BRANCH" main
        echo "created and "
    fi
    
    # Reset student branch to match main exactly
    git reset --hard main
    
    # Force push to remote (this overwrites the remote branch)
    git push --force-with-lease origin "$STUDENT_BRANCH"
    
    UPDATED_COUNT=$((UPDATED_COUNT + 1))
    echo "updated ✅"
    
    # Go back to main for next iteration
    git checkout main
done

echo ""
echo "✅ Branch updates complete!"
echo "   📊 Updated $UPDATED_COUNT student branches"
echo "   🌐 All student branches now have latest changes from main"
echo ""
echo "📝 Changes included in this update:"
echo "   • Updated cleanup.sh (student-safe version)"
echo "   • Added instructor-setup.sh (for cluster admin)"
echo "   • Added DAY3-CLEANUP-README.md (documentation)"
echo ""
echo "🎓 Students should now:"
echo "   git pull origin student01  # (or their assigned number)"
echo "   ./cleanup.sh               # (new student-safe version)"
echo ""
echo "🎯 Instructor should run:"
echo "   ./instructor-setup.sh      # (before students run cleanup)"