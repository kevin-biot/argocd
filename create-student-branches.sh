#!/bin/bash
# ------------------------------------------------------------------
# Create all 25 student branches from main branch
# Run this once after creating the mirror repo
# ------------------------------------------------------------------
set -euo pipefail

echo "🌿 Creating Student Branches for ArgoCD Workshop"
echo "==============================================="

# Ensure we're in a git repository
if [[ ! -d .git ]]; then
    echo "❌ Error: Not in a git repository root directory"
    echo "   Please run this script from your argocd repository root"
    exit 1
fi

# Ensure we're on main/master branch
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "main" && "$CURRENT_BRANCH" != "master" ]]; then
    echo "⚠️  Warning: Currently on branch '$CURRENT_BRANCH'"
    echo "   Switching to main branch..."
    git checkout main 2>/dev/null || git checkout master
fi

echo "📋 This will create 25 student branches: student01 through student25"
echo "   Each branch will be identical to main and pushed to origin"
read -rp "❓ Proceed with branch creation? (y/n): " CONFIRM
[[ "$CONFIRM" != [yY] ]] && { echo "❌ Aborted."; exit 1; }

echo ""
echo "🚀 Creating and pushing student branches..."

# Create and push all 25 branches
CREATED_COUNT=0
for i in {1..25}; do
    # Format with leading zero
    STUDENT_NUM=$(printf "%02d" $i)
    STUDENT_BRANCH="student${STUDENT_NUM}"
    echo -n "   Creating $STUDENT_BRANCH... "
    
    # Check if branch already exists locally
    if git branch --list | grep -q "$STUDENT_BRANCH"; then
        echo "already exists locally"
        git checkout "$STUDENT_BRANCH"
    else
        # Create branch from main
        git checkout -b "$STUDENT_BRANCH" main
        CREATED_COUNT=$((CREATED_COUNT + 1))
        echo "created"
    fi
    
    # Push branch to remote (will create or update)
    git push -u origin "$STUDENT_BRANCH"
    
    # Go back to main for next iteration
    git checkout main
done

echo ""
echo "✅ Branch creation complete!"
echo "   📊 Created $CREATED_COUNT new branches"
echo "   🌐 All 25 student branches are now available on GitHub"
echo ""
echo "🎓 Students can now:"
echo "   git clone <your-repo-url>"
echo "   git checkout student01  # (or their assigned number)"
echo "   # ... make changes ..."
echo "   git push"
echo ""
echo "🎯 Next steps:"
echo "   1. Students run: ./setup-student-pipeline.sh"
echo "   2. Students run: ./setup-git-credentials.sh" 
echo "   3. Students test their Tekton pipeline + ArgoCD sync"
