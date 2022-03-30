#!/usr/bin/env rdmd

import std.algorithm, std.conv, std.file, std.path, std.process, std.range, std.stdio;

auto digger = "dub run digger -- ";
auto dlangOrgFolder = "dlang.org";

void execute(string command, string[string] env = null)
{
    stderr.writefln("\033[1;33m---> Executing: %s\033[00m", command);
    auto pipes = pipeShell(command, Redirect.stdin, env);
    pipes.pid.wait;
}

void console(S...)(S args)
{
    stdout.write("\033[1;32m");
    stdout.write(args);
    stdout.writeln("\033[00m");
}

void main(string[] args)
{
    auto outFolder = "archives";
    outFolder.mkdirRecurse;

    console("Building digger...");
    execute("dub fetch digger");

    auto cwd = getcwd();
    auto tags = iota(78, 79).map!(e => text("v2.0", e, e >= 65 ? ".0" : ""));
    foreach (tag; tags)
    {
        auto diggerWorkRepo = cwd.buildPath("work", "repo");
        auto dlangOrgFolder = diggerWorkRepo.buildPath("dlang.org");
        auto installerFolder = diggerWorkRepo.buildPath("installer");
        auto web = dlangOrgFolder.buildPath("web");

        if (diggerWorkRepo.exists)
            diggerWorkRepo.rmdirRecurse;

        console("Checking out: ", tag);
        execute(digger ~ "checkout --with=website " ~ tag);
        execute("git -C " ~ diggerWorkRepo ~ " submodule update --init installer");
        execute("git -C " ~ installerFolder ~ " checkout " ~ tag);

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
        auto make = (string c) => execute("make -f posix.mak " ~ c ~ " -C " ~ dlangOrgFolder ~ folders, env);
        make("all");
        make("kindle");

        void removeFromWeb(string dir)
        {
            auto path = web.buildPath(dir);
            if (path.exists)
                path.rmdirRecurse;
        }
        removeFromWeb("phobos-prerelease");
        removeFromWeb("library-prerelease");

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
