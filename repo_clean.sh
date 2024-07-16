#!/bin/bash
set -ex

# Define the list of repositories
REPOS=(
    "https://bitbucket.org/repo1.git"
    "https://bitbucket.org/repo2.git"
)
DAYS_OLD=30  # Specify the number of days

# Function to process each repository
process_repo() {
    local repo_url=$1

    # Create a temporary directory for cloning
    tmp_dir=$(mktemp -d)
    echo "Cloning repository $repo_url into $tmp_dir"
    
    git clone "$repo_url" "$tmp_dir"
    cd "$tmp_dir" || exit
    
    # Fetch all branches and switch to master
    git fetch --all
    git checkout master
    git pull origin master

    # Find branches merged into master
    merged_branches=$(git branch -r --merged origin/master | sed 's|origin/||' | grep -v "master" | tr -d ' ')
    echo "Merged branches: $merged_branches"

    # Check if branches are older than the specified number of days
    current_time=$(date +%s)
    for branch in $merged_branches; do
        last_commit_date=$(git show -s --format=%ci "origin/$branch" | awk '{print $1" "$2}')
        last_commit_time=$(date -d "$last_commit_date" +%s)
        
        echo "Checking branch: $branch"
        echo "Last commit time: $last_commit_time ($last_commit_date)"
        echo "Current time: $current_time"

        if (( current_time - last_commit_time > DAYS_OLD * 86400 )); then
            echo "Deleting branch: $branch"
            git push origin --delete "$branch"
        fi
    done

    # Clean up
    cd ..
    rm -rf "$tmp_dir"
}

# Iterate over all repositories
for repo_url in "${REPOS[@]}"; do
    process_repo "$repo_url"
done
