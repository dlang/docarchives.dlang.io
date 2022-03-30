#!/usr/bin/env rdmd

import std.algorithm, std.conv, std.file, std.path, std.process, std.range, std.stdio;

auto digger = "dub run digger -- ";
auto dlangOrgFolder = "dlang.org";

int execute(string command, string[string] env = null)
{
    stderr.writefln("\033[1;33m---> Executing: %s\033[00m", command);
    auto pipes = pipeShell(command, Redirect.stdin, env);
    return pipes.pid.wait;
}

void executeOrFail(string command, string[string] env = null)
{
    import core.stdc.stdlib;
    execute(command, env) == 0 || exit(1);
}

void console(S...)(S args)
{
    stdout.write("\033[1;32m");
    stdout.write(args);
    stdout.writeln("\033[00m");
}

string tagVersion(int minor)
{
    return text("v2.", minor < 100 ? "0" : "", minor, minor >= 65 ? ".0" : "");
}

void main(string[] args)
{
    auto outFolder = "archives";
    outFolder.mkdirRecurse;

    console("Building digger...");
    executeOrFail("dub fetch digger");

    auto cwd = getcwd();
    auto tags = iota(78, 79).map!(e => tagVersion(e));
    foreach (tag; tags)
    {
        auto diggerWorkRepo = cwd.buildPath("work", "repo");
        auto dlangOrgFolder = diggerWorkRepo.buildPath("dlang.org");
        auto installerFolder = diggerWorkRepo.buildPath("installer");
        auto web = dlangOrgFolder.buildPath("web");

        // cleanup
        if (diggerWorkRepo.exists) 
        {
            auto removeWorkTree = (string p) => p.exists && p.remove;
            auto diggerModulePath = diggerWorkRepo.buildPath(".git", "modules");
            removeWorkTree(diggerModulePath.buildPath("dmd", "ae-sys-d-worktree.json"));
            removeWorkTree(diggerModulePath.buildPath("druntime", "ae-sys-d-worktree.json"));
            removeWorkTree(diggerModulePath.buildPath("phobos", "ae-sys-d-worktree.json"));
            removeWorkTree(diggerModulePath.buildPath("dlang.org", "ae-sys-d-worktree.json"));
            removeWorkTree(diggerModulePath.buildPath("installer", "ae-sys-d-worktree.json"));
            removeWorkTree(diggerModulePath.buildPath("tools", "ae-sys-d-worktree.json"));
        }

        // checkout
        console("Checking out: ", tag);
        executeOrFail(digger ~ "checkout --with=website " ~ tag);
        executeOrFail("git -C " ~ diggerWorkRepo ~ " submodule update --init installer");
        executeOrFail("git -C " ~ installerFolder ~ " checkout " ~ tag);

        // build
        console("Building: ", tag);
        auto env = [
            "NODATETIME": "nodatetime.ddoc"
        ];
        auto folders = " DMD_DIR=" ~ diggerWorkRepo.buildPath("dmd") ~
            " DRUNTIME_DIR=" ~ diggerWorkRepo.buildPath("druntime") ~
            " PHOBOS_DIR=" ~ diggerWorkRepo.buildPath("phobos") ~
            " INSTALLER_DIR=" ~ diggerWorkRepo.buildPath("installer") ~
            " TOOLS_DIR=" ~ diggerWorkRepo.buildPath("tools") ~
            " LATEST=" ~ tag[1..$];

        auto nextTag = tagVersion(tag.split(".")[1].to!int + 1);
        if (execute("git -C " ~ diggerWorkRepo ~ " show-ref --tags " ~ nextTag) == 0)
            folders ~= " CHANGELOG_VERSION_MASTER=" ~ tag ~ ".." ~ nextTag;

        auto make = (string c) => executeOrFail("make -f posix.mak " ~ c ~ " -C " ~ dlangOrgFolder ~ folders, env);
        make("all");
        make("kindle");

        auto removeFromWeb = (string d) => d.exists && d.rmdirRecurse;
        removeFromWeb(web.buildPath("phobos-prerelease"));
        removeFromWeb(web.buildPath("library-prerelease"));

        // save
        console("Storing: ", tag);
        auto target = outFolder.buildPath(tag);
        if (target.exists)
            target.rmdirRecurse;
        web.rename(target);
        dlangOrgFolder.buildPath(".generated", "docs-latest.json").rename(target.buildPath("docs.json"));
    }
    console(tags);
}
