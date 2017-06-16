#!/usr/bin/env rdmd

void main(string[] args)
{
    auto outFolder = "archives";
    auto dlangOrgFolder = "dlang.org";
    auto digger = "/home/seb/dlang/Digger/digger";

    import std.algorithm, std.conv, std.file, std.path, std.process, std.range, std.stdio;
    outFolder.mkdirRecurse;
    auto tags = iota(69, 75).map!(e => text("v2.0", e, e >= 65 ? ".0" : ""));
    foreach (tag; tags)
    {
        auto web = dlangOrgFolder.buildPath("web");

        writefln("Nuke web: %s", tag);
        if (web.exists)
            web.rmdirRecurse;

		// reset
		auto pipes = pipeShell("cd dlang.org && git clean -f && git checkout .");
        pipes.pid.wait;

		writefln("Checking out: %s", tag);
		foreach (file; ["dlang.org"])
		{
			executeShell("git -C " ~ dlangOrgFolder.dirName.buildPath(file) ~ " clean -f");
			executeShell("git -C " ~ dlangOrgFolder.dirName.buildPath(file) ~ " checkout " ~ tag);
			executeShell("make -C " ~ dlangOrgFolder.dirName.buildPath(file) ~ " clean");
		}

		pipes = pipeShell(digger ~ " checkout " ~ tag, Redirect.stdin);
		pipes.pid.wait;
        pipes = pipeShell(digger ~ " build " ~ tag, Redirect.stdin);
        pipes.pid.wait;
        auto env = [
            "DMD": "/dmd",
            "PATH": "/home/seb/dlang/docs/work/result/bin:/usr/local/sbin:/usr/local/bin:/usr/bin",
            "NODATETIME": "nodatetime.ddoc"
        ];
        env["DC"] = env["DMD"];
        auto diggerWorkRepo = "/home/seb/dlang/docs/work";
        auto folders = " DMD_DIR=" ~ diggerWorkRepo.buildPath("repo", "dmd") ~
					  " DRUNTIME_DIR=" ~ diggerWorkRepo.buildPath("repo", "druntime") ~
					  " PHOBOS_DIR=" ~ diggerWorkRepo.buildPath("repo", "phobos") ~
					  " INSTALLER_DIR=" ~ diggerWorkRepo.buildPath("repo", "installer") ~
					  " TOOLS_DIR=" ~ diggerWorkRepo.buildPath("repo", "tools") ~
					  " LATEST=" ~ tag[1..$];

		// hack to simulated cloned folders (<=2.0.68)
		/*foreach (folder; ["dmd", "druntime", "phobos"])*/
			/*std.file.write(diggerWorkRepo.buildPath("repo", folder, ".cloned"), "");*/

		auto posixMak = dlangOrgFolder.buildPath("posix.mak");
		std.file.write(posixMak, posixMak.readText.replace("| dpl-docs", ""));
		/*pipes = pipeShell("cd dlang.org/dpl-docs && dub upgrade && rm -rf /home/seb/.dub/packages/ddox-0.10.9", Redirect.stdin);*/
        /*pipes.pid.wait;*/

		folders.writeln;
        // build
        writefln("Building: %s", tag);
        pipes = pipeShell("make -f posix.mak all -C" ~ dlangOrgFolder ~ folders, Redirect.stdin, env);
        pipes.pid.wait;
        pipes = pipeShell("make -f posix.mak html pdf kindle -C" ~ dlangOrgFolder ~ folders, Redirect.stdin, env);
        pipes.pid.wait;
		pipes = pipeShell("make -f posix.mak docs-prerelease.json -C" ~ dlangOrgFolder ~ folders, Redirect.stdin, env);
		pipes.pid.wait;
        pipes = pipeShell("make -f posix.mak phobos-prerelease -C" ~ dlangOrgFolder ~ folders, Redirect.stdin, env);
        pipes.pid.wait;

        void renameInWeb(string from, string to)
        {
        	// rename phobos-prerelease to phobos
			auto webPhobos = web.buildPath(to);
        	if (webPhobos.exists)
        	    webPhobos.rmdirRecurse;

        	web.buildPath(from).rename(webPhobos);
        	// rewrite links
        	foreach (file; webPhobos.dirEntries(SpanMode.depth).filter!isFile)
        	{
        		auto text = file.readText;
        		text = text.replace(from, to);
        		std.file.write(file, text);
        	}
        }
		renameInWeb("phobos-prerelease", "phobos");
		/*renameInWeb("library-prerelease", "library");*/

        // save
        writefln("Storing: %s", tag);
        auto target = outFolder.buildPath(tag);
        if (!target.exists)
            web.rename(target);
        else
        {
            foreach (file; web.dirEntries(SpanMode.depth).filter!isFile)
            {
                auto t = target.buildPath(file.absolutePath.relativePath(web.absolutePath));
                t.dirName.mkdirRecurse;
                file.rename(t);
            }
            dlangOrgFolder.buildPath("docs-prerelease.json").rename(target.buildPath("docs.json"));
        }
    }
    tags.writeln;
}
