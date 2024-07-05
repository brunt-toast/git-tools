use git2::{Repository, Commit, Oid};
use git2::build::CheckoutBuilder;
use std::env;
use std::process;

fn main() {
    let args: Vec<_> = env::args().collect();

    if args.len() != 2 {
        eprintln!("{} takes one positional argument, but {} were given.", args[0], args.len() - 1);
        process::exit(1);
    }

    let n_commits = match args[1].parse::<i32>() {
        Ok(v) => v,
        Err(_) => { 
            eprintln!("Could not convert value \"{}\" to 32-bit integer.", args[1]);
            process::exit(1);
        }
    };

    let cwd = env::current_dir().expect("Could not determine the current directory");

    let repo = get_repo();

    let head = match repo.head() {
        Ok(head) => head,
        Err(e) => {
            eprintln!("Failed to get HEAD: {}", e);
            process::exit(1);
        }
    };

    let commit_oid = match head.target() {
        Some(oid) => oid,
        None => {
            eprintln!("Failed to get the commit hash of the HEAD commit");
            process::exit(1);
        }
    };
    println!("Currently checked out commit: {}", commit_oid);

    let commit = match repo.find_commit(commit_oid) {
        Ok(commit) => commit,
        Err(e) => {
            eprintln!("Failed to find head commit from hash: {}", e);
            process::exit(1);
        }
    };

    move_commits(n_commits, commit.clone());

    println!("Parents:");
    for parent_id in commit.parent_ids() {
        println!("{}", parent_id);
    }
}

fn move_commits(n_commits: i32, starting_commit: Commit<'_>) {
    if n_commits < 0 {
        move_back_commits(n_commits * -1, starting_commit);
        return;
    }

    if n_commits > 0 {
        move_forward_commits(n_commits, starting_commit);
        return;
    }
}

fn move_forward_commits(_n_commits: i32, _starting_commit: Commit<'_>) {

}

fn move_back_commits(n_commits: i32, starting_commit: Commit<'_>) {
    if n_commits == 0 {
        checkout_commit(starting_commit.id().to_string());
        return; 
    }

    let mut parents = starting_commit.parent_ids();

    if parents.len() == 0 {
        eprintln!("Could not complete action: A commit in the path has no parents");
        process::exit(1);
    }

    if parents.len() > 1 {
        eprintln!("Could not complete action: A commit in the path has multiple parents");
        process::exit(1);
    }

    let repo = get_repo();

    let oid_str = parents.next().expect("Could not get parent commit").to_string();
    let commit_oid = match Oid::from_str(&oid_str) {
        Ok(oid) => oid,
        Err(e) => {
            eprintln!("Could not parse commit ID for parent of {}: {}", starting_commit.id().to_string(), e);
            process::exit(1);
        }
    };

    let commit = match repo.find_commit(commit_oid) {
        Ok(commit) => commit,
        Err(e) => {
            eprintln!("Failed to find commit for checkout: {}", e);
            process::exit(1);
        }
    };

    move_back_commits(n_commits - 1, commit)
}

fn get_repo() -> Repository {
    let cwd = env::current_dir().expect("Could not determine the current directory");

    return match Repository::open(cwd) {
        Ok(repo) => repo,
        Err(e) => {
            eprintln!("Failed to open the git repository: {}", e);
            process::exit(1);
        }
    };
}

fn checkout_commit(oid_str: String) {
    let repo = get_repo();

    let commit_oid = match Oid::from_str(&oid_str) {
        Ok(oid) => oid,
        Err(e) => {
            eprintln!("Could not parse commit ID for checkout: {}", e);
            process::exit(1);
        }
    };

    let commit = match repo.find_commit(commit_oid) {
        Ok(commit) => commit,
        Err(e) => {
            eprintln!("Failed to find commit for checkout: {}", e);
            process::exit(1);
        }
    };

    let tree = commit.tree().expect("Could not find commit's tree");
    repo.set_head_detached(commit.id()).expect("Could not set detached HEAD");
    let mut checkout_builder = CheckoutBuilder::new();
    let _ = repo.checkout_tree(&tree.as_object(), Some(&mut checkout_builder));
}
