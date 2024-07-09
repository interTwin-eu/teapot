[4mGIT-REBASE[24m(1)                                                               Git Manual                                                               [4mGIT-REBASE[24m(1)

[1mNAME[0m
       git-rebase - Reapply commits on top of another base tip

[1mSYNOPSIS[0m
       [4mgit[24m [4mrebase[24m [-i | --interactive] [<options>] [--exec <cmd>]
               [--onto <newbase> | --keep-base] [<upstream> [<branch>]]
       [4mgit[24m [4mrebase[24m [-i | --interactive] [<options>] [--exec <cmd>] [--onto <newbase>]
               --root [<branch>]
       [4mgit[24m [4mrebase[24m (--continue | --skip | --abort | --quit | --edit-todo | --show-current-patch)

[1mDESCRIPTION[0m
       If [1m<branch> [22mis specified, [1mgit rebase [22mwill perform an automatic [1mgit switch <branch> [22mbefore doing anything else. Otherwise it remains on the current branch.

       If [1m<upstream> [22mis not specified, the upstream configured in [1mbranch.<name>.remote [22mand [1mbranch.<name>.merge [22moptions will be used (see [1mgit-config[22m(1) for
       details) and the [1m--fork-point [22moption is assumed. If you are currently not on any branch or if the current branch does not have a configured upstream, the
       rebase will abort.

       All changes made by commits in the current branch but that are not in [1m<upstream> [22mare saved to a temporary area. This is the same set of commits that would
       be shown by [1mgit log <upstream>..HEAD[22m; or by [1mgit log 'fork_point'..HEAD[22m, if [1m--fork-point [22mis active (see the description on [1m--fork-point [22mbelow); or by [1mgit[0m
       [1mlog HEAD[22m, if the [1m--root [22moption is specified.

       The current branch is reset to [1m<upstream> [22mor [1m<newbase> [22mif the [1m--onto [22moption was supplied. This has the exact same effect as [1mgit reset --hard <upstream> [22m(or
       [1m<newbase>[22m). [1mORIG_HEAD [22mis set to point at the tip of the branch before the reset.

           [1mNote[0m

           [1mORIG_HEAD [22mis not guaranteed to still point to the previous branch tip at the end of the rebase if other commands that write that pseudo-ref (e.g. [1mgit[0m
           [1mreset[22m) are used during the rebase. The previous branch tip, however, is accessible using the reflog of the current branch (i.e. [1m@{1}[22m, see
           [1mgitrevisions[22m(7)).

       The commits that were previously saved into the temporary area are then reapplied to the current branch, one by one, in order. Note that any commits in
       [1mHEAD [22mwhich introduce the same textual changes as a commit in [1mHEAD..<upstream> [22mare omitted (i.e., a patch already accepted upstream with a different commit
       message or timestamp will be skipped).

       It is possible that a merge failure will prevent this process from being completely automatic. You will have to resolve any such merge failure and run [1mgit[0m
       [1mrebase --continue[22m. Another option is to bypass the commit that caused the merge failure with [1mgit rebase --skip[22m. To check out the original [1m<branch> [22mand
       remove the [1m.git/rebase-apply [22mworking files, use the command [1mgit rebase --abort [22minstead.

       Assume the following history exists and the current branch is "topic":

                     A---B---C topic
                    /
               D---E---F---G master

       From this point, the result of either of the following commands:

           git rebase master
           git rebase master topic

       would be:

                             A'--B'--C' topic
                            /
               D---E---F---G master

       [1mNOTE: [22mThe latter form is just a short-hand of [1mgit checkout topic [22mfollowed by [1mgit rebase master[22m. When rebase exits [1mtopic [22mwill remain the checked-out branch.

       If the upstream branch already contains a change you have made (e.g., because you mailed a patch which was applied upstream), then that commit will be
       skipped and warnings will be issued (if the [4mmerge[24m backend is used). For example, running [1mgit rebase master [22mon the following history (in which [1mA' [22mand [1mA[0m
       introduce the same set of changes, but have different committer information):

                     A---B---C topic
                    /
               D---E---A'---F master

       will result in:

                              B'---C' topic
                             /
               D---E---A'---F master

       Here is how you would transplant a topic branch based on one branch to another, to pretend that you forked the topic branch from the latter branch, using
       [1mrebase --onto[22m.

       First let’s assume your [4mtopic[24m is based on branch [4mnext[24m. For example, a feature developed in [4mtopic[24m depends on some functionality which is found in [4mnext[24m.

               o---o---o---o---o  master
                    \
                     o---o---o---o---o  next
                                      \
                                       o---o---o  topic

       We want to make [4mtopic[24m forked from branch [4mmaster[24m; for example, because the functionality on which [4mtopic[24m depends was merged into the more stable [4mmaster[0m
       branch. We want our tree to look like this:

               o---o---o---o---o  master
                   |            \
                   |             o'--o'--o'  topic
                    \
                     o---o---o---o---o  next

       We can get this using the following command:

           git rebase --onto master next topic

       Another example of --onto option is to rebase part of a branch. If we have the following situation:

                                       H---I---J topicB
                                      /
                             E---F---G  topicA
                            /
               A---B---C---D  master

       then the command

           git rebase --onto master topicA topicB

       would result in:

                            H'--I'--J'  topicB
                           /
                           | E---F---G  topicA
                           |/
               A---B---C---D  master

       This is useful when topicB does not depend on topicA.

       A range of commits could also be removed with rebase. If we have the following situation:

               E---F---G---H---I---J  topicA

       then the command

           git rebase --onto topicA~5 topicA~3 topicA

       would result in the removal of commits F and G:

               E---H'---I'---J'  topicA

       This is useful if F and G were flawed in some way, or should not be part of topicA. Note that the argument to [1m--onto [22mand the [1m<upstream> [22mparameter can be
       any valid commit-ish.

       In case of conflict, [1mgit rebase [22mwill stop at the first problematic commit and leave conflict markers in the tree. You can use [1mgit diff [22mto locate the
       markers (<<<<<<) and make edits to resolve the conflict. For each file you edit, you need to tell Git that the conflict has been resolved, typically this
       would be done with

           git add <filename>

       After resolving the conflict manually and updating the index with the desired resolution, you can continue the rebasing process with

           git rebase --continue

       Alternatively, you can undo the [4mgit[24m [4mrebase[24m with

           git rebase --abort

[1mMODE OPTIONS[0m
       The options in this section cannot be used with any other option, including not with each other:

       --continue
           Restart the rebasing process after having resolved a merge conflict.

       --skip
           Restart the rebasing process by skipping the current patch.

       --abort
           Abort the rebase operation and reset HEAD to the original branch. If [1m<branch> [22mwas provided when the rebase operation was started, then [1mHEAD [22mwill be
           reset to [1m<branch>[22m. Otherwise [1mHEAD [22mwill be reset to where it was when the rebase operation was started.

       --quit
           Abort the rebase operation but [1mHEAD [22mis not reset back to the original branch. The index and working tree are also left unchanged as a result. If a
           temporary stash entry was created using [1m--autostash[22m, it will be saved to the stash list.

       --edit-todo
           Edit the todo list during an interactive rebase.

       --show-current-patch
           Show the current patch in an interactive rebase or when rebase is stopped because of conflicts. This is the equivalent of [1mgit show REBASE_HEAD[22m.

[1mOPTIONS[0m
       --onto <newbase>
           Starting point at which to create the new commits. If the [1m--onto [22moption is not specified, the starting point is [1m<upstream>[22m. May be any valid commit,
           and not just an existing branch name.

           As a special case, you may use "A...B" as a shortcut for the merge base of A and B if there is exactly one merge base. You can leave out at most one of
           A and B, in which case it defaults to HEAD.

       --keep-base
           Set the starting point at which to create the new commits to the merge base of [1m<upstream> [22mand [1m<branch>[22m. Running [1mgit rebase --keep-base <upstream>[0m
           [1m<branch> [22mis equivalent to running [1mgit rebase --reapply-cherry-picks --no-fork-point --onto <upstream>...<branch> <upstream> <branch>[22m.

           This option is useful in the case where one is developing a feature on top of an upstream branch. While the feature is being worked on, the upstream
           branch may advance and it may not be the best idea to keep rebasing on top of the upstream but to keep the base commit as-is. As the base commit is
           unchanged this option implies [1m--reapply-cherry-picks [22mto avoid losing commits.

           Although both this option and [1m--fork-point [22mfind the merge base between [1m<upstream> [22mand [1m<branch>[22m, this option uses the merge base as the [4mstarting[24m [4mpoint[0m
           on which new commits will be created, whereas [1m--fork-point [22muses the merge base to determine the [4mset[24m [4mof[24m [4mcommits[24m which will be rebased.

           See also INCOMPATIBLE OPTIONS below.

       <upstream>
           Upstream branch to compare against. May be any valid commit, not just an existing branch name. Defaults to the configured upstream for the current
           branch.

       <branch>
           Working branch; defaults to [1mHEAD[22m.

       --apply
           Use applying strategies to rebase (calling [1mgit-am [22minternally). This option may become a no-op in the future once the merge backend handles everything
           the apply one does.

           See also INCOMPATIBLE OPTIONS below.

       --empty=(drop|keep|ask)
           How to handle commits that are not empty to start and are not clean cherry-picks of any upstream commit, but which become empty after rebasing (because
           they contain a subset of already upstream changes). With drop (the default), commits that become empty are dropped. With keep, such commits are kept.
           With ask (implied by [1m--interactive[22m), the rebase will halt when an empty commit is applied allowing you to choose whether to drop it, edit files more,
           or just commit the empty changes. Other options, like [1m--exec[22m, will use the default of drop unless [1m-i[22m/[1m--interactive [22mis explicitly specified.

           Note that commits which start empty are kept (unless [1m--no-keep-empty [22mis specified), and commits which are clean cherry-picks (as determined by [1mgit log[0m
           [1m--cherry-mark ...[22m) are detected and dropped as a preliminary step (unless [1m--reapply-cherry-picks [22mor [1m--keep-base [22mis passed).

           See also INCOMPATIBLE OPTIONS below.

       --no-keep-empty, --keep-empty
           Do not keep commits that start empty before the rebase (i.e. that do not change anything from its parent) in the result. The default is to keep commits
           which start empty, since creating such commits requires passing the [1m--allow-empty [22moverride flag to [1mgit commit[22m, signifying that a user is very
           intentionally creating such a commit and thus wants to keep it.

           Usage of this flag will probably be rare, since you can get rid of commits that start empty by just firing up an interactive rebase and removing the
           lines corresponding to the commits you don’t want. This flag exists as a convenient shortcut, such as for cases where external tools generate many
           empty commits and you want them all removed.

           For commits which do not start empty but become empty after rebasing, see the [1m--empty [22mflag.

           See also INCOMPATIBLE OPTIONS below.

       --reapply-cherry-picks, --no-reapply-cherry-picks
           Reapply all clean cherry-picks of any upstream commit instead of preemptively dropping them. (If these commits then become empty after rebasing,
           because they contain a subset of already upstream changes, the behavior towards them is controlled by the [1m--empty [22mflag.)

           In the absence of [1m--keep-base [22m(or if [1m--no-reapply-cherry-picks [22mis given), these commits will be automatically dropped. Because this necessitates
           reading all upstream commits, this can be expensive in repositories with a large number of upstream commits that need to be read. When using the [4mmerge[0m
           backend, warnings will be issued for each dropped commit (unless [1m--quiet [22mis given). Advice will also be issued unless [1madvice.skippedCherryPicks [22mis set
           to false (see [1mgit-config[22m(1)).

           [1m--reapply-cherry-picks [22mallows rebase to forgo reading all upstream commits, potentially improving performance.

           See also INCOMPATIBLE OPTIONS below.

       --allow-empty-message
           No-op. Rebasing commits with an empty message used to fail and this option would override that behavior, allowing commits with empty messages to be
           rebased. Now commits with an empty message do not cause rebasing to halt.

           See also INCOMPATIBLE OPTIONS below.

       -m, --merge
           Using merging strategies to rebase (default).

           Note that a rebase merge works by replaying each commit from the working branch on top of the [1m<upstream> [22mbranch. Because of this, when a merge conflict
           happens, the side reported as [4mours[24m is the so-far rebased series, starting with [1m<upstream>[22m, and [4mtheirs[24m is the working branch. In other words, the sides
           are swapped.

           See also INCOMPATIBLE OPTIONS below.

       -s <strategy>, --strategy=<strategy>
           Use the given merge strategy, instead of the default [1mort[22m. This implies [1m--merge[22m.

           Because [1mgit rebase [22mreplays each commit from the working branch on top of the [1m<upstream> [22mbranch using the given strategy, using the [1mours [22mstrategy simply
           empties all patches from the [1m<branch>[22m, which makes little sense.

           See also INCOMPATIBLE OPTIONS below.

       -X <strategy-option>, --strategy-option=<strategy-option>
           Pass the <strategy-option> through to the merge strategy. This implies [1m--merge [22mand, if no strategy has been specified, [1m-s ort[22m. Note the reversal of
           [4mours[24m and [4mtheirs[24m as noted above for the [1m-m [22moption.

           See also INCOMPATIBLE OPTIONS below.

       --rerere-autoupdate, --no-rerere-autoupdate
           After the rerere mechanism reuses a recorded resolution on the current conflict to update the files in the working tree, allow it to also update the
           index with the result of resolution.  [1m--no-rerere-autoupdate [22mis a good way to double-check what [1mrerere [22mdid and catch potential mismerges, before
           committing the result to the index with a separate [1mgit add[22m.

       -S[<keyid>], --gpg-sign[=<keyid>], --no-gpg-sign
           GPG-sign commits. The [1mkeyid [22margument is optional and defaults to the committer identity; if specified, it must be stuck to the option without a space.
           [1m--no-gpg-sign [22mis useful to countermand both [1mcommit.gpgSign [22mconfiguration variable, and earlier [1m--gpg-sign[22m.

       -q, --quiet
           Be quiet. Implies [1m--no-stat[22m.

       -v, --verbose
           Be verbose. Implies [1m--stat[22m.

       --stat
           Show a diffstat of what changed upstream since the last rebase. The diffstat is also controlled by the configuration option rebase.stat.

       -n, --no-stat
           Do not show a diffstat as part of the rebase process.

       --no-verify
           This option bypasses the pre-rebase hook. See also [1mgithooks[22m(5).

       --verify
           Allows the pre-rebase hook to run, which is the default. This option can be used to override [1m--no-verify[22m. See also [1mgithooks[22m(5).

       -C<n>
           Ensure at least [1m<n> [22mlines of surrounding context match before and after each change. When fewer lines of surrounding context exist they all must match.
           By default no context is ever ignored. Implies [1m--apply[22m.

           See also INCOMPATIBLE OPTIONS below.

       --no-ff, --force-rebase, -f
           Individually replay all rebased commits instead of fast-forwarding over the unchanged ones. This ensures that the entire history of the rebased branch
           is composed of new commits.

           You may find this helpful after reverting a topic branch merge, as this option recreates the topic branch with fresh commits so it can be remerged
           successfully without needing to "revert the reversion" (see the [34m[1mrevert-a-faulty-merge How-To[0m[1m[22m[1] for details).

       --fork-point, --no-fork-point
           Use reflog to find a better common ancestor between [1m<upstream> [22mand [1m<branch> [22mwhen calculating which commits have been introduced by [1m<branch>[22m.

           When [1m--fork-point [22mis active, [4mfork_point[24m will be used instead of [1m<upstream> [22mto calculate the set of commits to rebase, where [4mfork_point[24m is the result of
           [1mgit merge-base --fork-point <upstream> <branch> [22mcommand (see [1mgit-merge-base[22m(1)). If [4mfork_point[24m ends up being empty, the [1m<upstream> [22mwill be used as a
           fallback.

           If [1m<upstream> [22mor [1m--keep-base [22mis given on the command line, then the default is [1m--no-fork-point[22m, otherwise the default is [1m--fork-point[22m. See also
           [1mrebase.forkpoint [22min [1mgit-config[22m(1).

           If your branch was based on [1m<upstream> [22mbut [1m<upstream> [22mwas rewound and your branch contains commits which were dropped, this option can be used with
           [1m--keep-base [22min order to drop those commits from your branch.

           See also INCOMPATIBLE OPTIONS below.

       --ignore-whitespace
           Ignore whitespace differences when trying to reconcile differences. Currently, each backend implements an approximation of this behavior:

           apply backend
               When applying a patch, ignore changes in whitespace in context lines. Unfortunately, this means that if the "old" lines being replaced by the patch
               differ only in whitespace from the existing file, you will get a merge conflict instead of a successful patch application.

           merge backend
               Treat lines with only whitespace changes as unchanged when merging. Unfortunately, this means that any patch hunks that were intended to modify
               whitespace and nothing else will be dropped, even if the other side had no changes that conflicted.

       --whitespace=<option>
           This flag is passed to the [1mgit apply [22mprogram (see [1mgit-apply[22m(1)) that applies the patch. Implies [1m--apply[22m.

           See also INCOMPATIBLE OPTIONS below.

       --committer-date-is-author-date
           Instead of using the current time as the committer date, use the author date of the commit being rebased as the committer date. This option implies
           [1m--force-rebase[22m.

       --ignore-date, --reset-author-date
           Instead of using the author date of the original commit, use the current time as the author date of the rebased commit. This option implies
           [1m--force-rebase[22m.

           See also INCOMPATIBLE OPTIONS below.

       --signoff
           Add a [1mSigned-off-by [22mtrailer to all the rebased commits. Note that if [1m--interactive [22mis given then only commits marked to be picked, edited or reworded
           will have the trailer added.

           See also INCOMPATIBLE OPTIONS below.

       -i, --interactive
           Make a list of the commits which are about to be rebased. Let the user edit that list before rebasing. This mode can also be used to split commits (see
           SPLITTING COMMITS below).

           The commit list format can be changed by setting the configuration option rebase.instructionFormat. A customized instruction format will automatically
           have the long commit hash prepended to the format.

           See also INCOMPATIBLE OPTIONS below.

       -r, --rebase-merges[=(rebase-cousins|no-rebase-cousins)], --no-rebase-merges
           By default, a rebase will simply drop merge commits from the todo list, and put the rebased commits into a single, linear branch. With [1m--rebase-merges[22m,
           the rebase will instead try to preserve the branching structure within the commits that are to be rebased, by recreating the merge commits. Any
           resolved merge conflicts or manual amendments in these merge commits will have to be resolved/re-applied manually.  [1m--no-rebase-merges [22mcan be used to
           countermand both the [1mrebase.rebaseMerges [22mconfig option and a previous [1m--rebase-merges[22m.

           When rebasing merges, there are two modes: [1mrebase-cousins [22mand [1mno-rebase-cousins[22m. If the mode is not specified, it defaults to [1mno-rebase-cousins[22m. In
           [1mno-rebase-cousins [22mmode, commits which do not have [1m<upstream> [22mas direct ancestor will keep their original branch point, i.e. commits that would be
           excluded by [1mgit-log[22m(1)'s [1m--ancestry-path [22moption will keep their original ancestry by default. In [1mrebase-cousins [22mmode, such commits are instead rebased
           onto [1m<upstream> [22m(or [1m<onto>[22m, if specified).

           It is currently only possible to recreate the merge commits using the [1mort [22mmerge strategy; different merge strategies can be used only via explicit [1mexec[0m
           [1mgit merge -s <strategy> [...]  [22mcommands.

           See also REBASING MERGES and INCOMPATIBLE OPTIONS below.

       -x <cmd>, --exec <cmd>
           Append "exec <cmd>" after each line creating a commit in the final history.  [1m<cmd> [22mwill be interpreted as one or more shell commands. Any command that
           fails will interrupt the rebase, with exit code 1.

           You may execute several commands by either using one instance of [1m--exec [22mwith several commands:

               git rebase -i --exec "cmd1 && cmd2 && ..."

           or by giving more than one [1m--exec[22m:

               git rebase -i --exec "cmd1" --exec "cmd2" --exec ...

           If [1m--autosquash [22mis used, [1mexec [22mlines will not be appended for the intermediate commits, and will only appear at the end of each squash/fixup series.

           This uses the [1m--interactive [22mmachinery internally, but it can be run without an explicit [1m--interactive[22m.

           See also INCOMPATIBLE OPTIONS below.

       --root
           Rebase all commits reachable from [1m<branch>[22m, instead of limiting them with an [1m<upstream>[22m. This allows you to rebase the root commit(s) on a branch.

           See also INCOMPATIBLE OPTIONS below.

       --autosquash, --no-autosquash
           When the commit log message begins with "squash! ..." or "fixup! ..." or "amend! ...", and there is already a commit in the todo list that matches the
           same [1m...[22m, automatically modify the todo list of [1mrebase -i[22m, so that the commit marked for squashing comes right after the commit to be modified, and
           change the action of the moved commit from [1mpick [22mto [1msquash [22mor [1mfixup [22mor [1mfixup -C [22mrespectively. A commit matches the [1m...  [22mif the commit subject matches,
           or if the [1m...  [22mrefers to the commit’s hash. As a fall-back, partial matches of the commit subject work, too. The recommended way to create
           fixup/amend/squash commits is by using the [1m--fixup[22m, [1m--fixup=amend: [22mor [1m--fixup=reword: [22mand [1m--squash [22moptions respectively of [1mgit-commit[22m(1).

           If the [1m--autosquash [22moption is enabled by default using the configuration variable [1mrebase.autoSquash[22m, this option can be used to override and disable
           this setting.

           See also INCOMPATIBLE OPTIONS below.

       --autostash, --no-autostash
           Automatically create a temporary stash entry before the operation begins, and apply it after the operation ends. This means that you can run rebase on
           a dirty worktree. However, use with care: the final stash application after a successful rebase might result in non-trivial conflicts.

       --reschedule-failed-exec, --no-reschedule-failed-exec
           Automatically reschedule [1mexec [22mcommands that failed. This only makes sense in interactive mode (or when an [1m--exec [22moption was provided).

           Even though this option applies once a rebase is started, it’s set for the whole rebase at the start based on either the [1mrebase.rescheduleFailedExec[0m
           configuration (see [1mgit-config[22m(1) or "CONFIGURATION" below) or whether this option is provided. Otherwise an explicit [1m--no-reschedule-failed-exec [22mat the
           start would be overridden by the presence of [1mrebase.rescheduleFailedExec=true [22mconfiguration.

       --update-refs, --no-update-refs
           Automatically force-update any branches that point to commits that are being rebased. Any branches that are checked out in a worktree are not updated
           in this way.

           If the configuration variable [1mrebase.updateRefs [22mis set, then this option can be used to override and disable this setting.

           See also INCOMPATIBLE OPTIONS below.

[1mINCOMPATIBLE OPTIONS[0m
       The following options:

       •   --apply

       •   --whitespace

       •   -C

       are incompatible with the following options:

       •   --merge

       •   --strategy

       •   --strategy-option

       •   --autosquash

       •   --rebase-merges

       •   --interactive

       •   --exec

       •   --no-keep-empty

       •   --empty=

       •   --[no-]reapply-cherry-picks when used without --keep-base

       •   --update-refs

       •   --root when used without --onto

       In addition, the following pairs of options are incompatible:

       •   --keep-base and --onto

       •   --keep-base and --root

       •   --fork-point and --root

[1mBEHAVIORAL DIFFERENCES[0m
       [1mgit rebase [22mhas two primary backends: [4mapply[24m and [4mmerge[24m. (The [4mapply[24m backend used to be known as the [4mam[24m backend, but the name led to confusion as it looks like
       a verb instead of a noun. Also, the [4mmerge[24m backend used to be known as the interactive backend, but it is now used for non-interactive cases as well. Both
       were renamed based on lower-level functionality that underpinned each.) There are some subtle differences in how these two backends behave:

   [1mEmpty commits[0m
       The [4mapply[24m backend unfortunately drops intentionally empty commits, i.e. commits that started empty, though these are rare in practice. It also drops
       commits that become empty and has no option for controlling this behavior.

       The [4mmerge[24m backend keeps intentionally empty commits by default (though with [1m-i [22mthey are marked as empty in the todo list editor, or they can be dropped
       automatically with [1m--no-keep-empty[22m).

       Similar to the apply backend, by default the merge backend drops commits that become empty unless [1m-i[22m/[1m--interactive [22mis specified (in which case it stops and
       asks the user what to do). The merge backend also has an [1m--empty=(drop|keep|ask) [22moption for changing the behavior of handling commits that become empty.

   [1mDirectory rename detection[0m
       Due to the lack of accurate tree information (arising from constructing fake ancestors with the limited information available in patches), directory rename
       detection is disabled in the [4mapply[24m backend. Disabled directory rename detection means that if one side of history renames a directory and the other adds
       new files to the old directory, then the new files will be left behind in the old directory without any warning at the time of rebasing that you may want
       to move these files into the new directory.

       Directory rename detection works with the [4mmerge[24m backend to provide you warnings in such cases.

   [1mContext[0m
       The [4mapply[24m backend works by creating a sequence of patches (by calling [1mformat-patch [22minternally), and then applying the patches in sequence (calling [1mam[0m
       internally). Patches are composed of multiple hunks, each with line numbers, a context region, and the actual changes. The line numbers have to be taken
       with some fuzz, since the other side will likely have inserted or deleted lines earlier in the file. The context region is meant to help find how to adjust
       the line numbers in order to apply the changes to the right lines. However, if multiple areas of the code have the same surrounding lines of context, the
       wrong one can be picked. There are real-world cases where this has caused commits to be reapplied incorrectly with no conflicts reported. Setting
       [1mdiff.context [22mto a larger value may prevent such types of problems, but increases the chance of spurious conflicts (since it will require more lines of
       matching context to apply).

       The [4mmerge[24m backend works with a full copy of each relevant file, insulating it from these types of problems.

   [1mLabelling of conflicts markers[0m
       When there are content conflicts, the merge machinery tries to annotate each side’s conflict markers with the commits where the content came from. Since
       the [4mapply[24m backend drops the original information about the rebased commits and their parents (and instead generates new fake commits based off limited
       information in the generated patches), those commits cannot be identified; instead it has to fall back to a commit summary. Also, when [1mmerge.conflictStyle[0m
       is set to [1mdiff3 [22mor [1mzdiff3[22m, the [4mapply[24m backend will use "constructed merge base" to label the content from the merge base, and thus provide no information
       about the merge base commit whatsoever.

       The [4mmerge[24m backend works with the full commits on both sides of history and thus has no such limitations.

   [1mHooks[0m
       The [4mapply[24m backend has not traditionally called the post-commit hook, while the [4mmerge[24m backend has. Both have called the post-checkout hook, though the [4mmerge[0m
       backend has squelched its output. Further, both backends only call the post-checkout hook with the starting point commit of the rebase, not the
       intermediate commits nor the final commit. In each case, the calling of these hooks was by accident of implementation rather than by design (both backends
       were originally implemented as shell scripts and happened to invoke other commands like [1mgit checkout [22mor [1mgit commit [22mthat would call the hooks). Both
       backends should have the same behavior, though it is not entirely clear which, if any, is correct. We will likely make rebase stop calling either of these
       hooks in the future.

   [1mInterruptability[0m
       The [4mapply[24m backend has safety problems with an ill-timed interrupt; if the user presses Ctrl-C at the wrong time to try to abort the rebase, the rebase can
       enter a state where it cannot be aborted with a subsequent [1mgit rebase --abort[22m. The [4mmerge[24m backend does not appear to suffer from the same shortcoming. (See
       [34m[1mhttps://lore.kernel.org/git/20200207132152.GC2868@szeder.dev/ [0m[1m[22mfor details.)

   [1mCommit Rewording[0m
       When a conflict occurs while rebasing, rebase stops and asks the user to resolve. Since the user may need to make notable changes while resolving
       conflicts, after conflicts are resolved and the user has run [1mgit rebase --continue[22m, the rebase should open an editor and ask the user to update the commit
       message. The [4mmerge[24m backend does this, while the [4mapply[24m backend blindly applies the original commit message.

   [1mMiscellaneous differences[0m
       There are a few more behavioral differences that most folks would probably consider inconsequential but which are mentioned for completeness:

       •   Reflog: The two backends will use different wording when describing the changes made in the reflog, though both will make use of the word "rebase".

       •   Progress, informational, and error messages: The two backends provide slightly different progress and informational messages. Also, the apply backend
           writes error messages (such as "Your files would be overwritten...") to stdout, while the merge backend writes them to stderr.

       •   State directories: The two backends keep their state in different directories under [1m.git/[0m

[1mMERGE STRATEGIES[0m
       The merge mechanism ([1mgit merge [22mand [1mgit pull [22mcommands) allows the backend [4mmerge[24m [4mstrategies[24m to be chosen with [1m-s [22moption. Some strategies can also take their
       own options, which can be passed by giving [1m-X<option> [22marguments to [1mgit merge [22mand/or [1mgit pull[22m.

       ort
           This is the default merge strategy when pulling or merging one branch. This strategy can only resolve two heads using a 3-way merge algorithm. When
           there is more than one common ancestor that can be used for 3-way merge, it creates a merged tree of the common ancestors and uses that as the
           reference tree for the 3-way merge. This has been reported to result in fewer merge conflicts without causing mismerges by tests done on actual merge
           commits taken from Linux 2.6 kernel development history. Additionally this strategy can detect and handle merges involving renames. It does not make
           use of detected copies. The name for this algorithm is an acronym ("Ostensibly Recursive’s Twin") and came from the fact that it was written as a
           replacement for the previous default algorithm, [1mrecursive[22m.

           The [4mort[24m strategy can take the following options:

           ours
               This option forces conflicting hunks to be auto-resolved cleanly by favoring [4mour[24m version. Changes from the other tree that do not conflict with our
               side are reflected in the merge result. For a binary file, the entire contents are taken from our side.

               This should not be confused with the [4mours[24m merge strategy, which does not even look at what the other tree contains at all. It discards everything
               the other tree did, declaring [4mour[24m history contains all that happened in it.

           theirs
               This is the opposite of [4mours[24m; note that, unlike [4mours[24m, there is no [4mtheirs[24m merge strategy to confuse this merge option with.

           ignore-space-change, ignore-all-space, ignore-space-at-eol, ignore-cr-at-eol
               Treats lines with the indicated type of whitespace change as unchanged for the sake of a three-way merge. Whitespace changes mixed with other
               changes to a line are not ignored. See also [1mgit-diff[22m(1) [1m-b[22m, [1m-w[22m, [1m--ignore-space-at-eol[22m, and [1m--ignore-cr-at-eol[22m.

               •   If [4mtheir[24m version only introduces whitespace changes to a line, [4mour[24m version is used;

               •   If [4mour[24m version introduces whitespace changes but [4mtheir[24m version includes a substantial change, [4mtheir[24m version is used;

               •   Otherwise, the merge proceeds in the usual way.

           renormalize
               This runs a virtual check-out and check-in of all three stages of a file when resolving a three-way merge. This option is meant to be used when
               merging branches with different clean filters or end-of-line normalization rules. See "Merging branches with differing checkin/checkout attributes"
               in [1mgitattributes[22m(5) for details.

           no-renormalize
               Disables the [1mrenormalize [22moption. This overrides the [1mmerge.renormalize [22mconfiguration variable.

           find-renames[=<n>]
               Turn on rename detection, optionally setting the similarity threshold. This is the default. This overrides the [4mmerge.renames[24m configuration
               variable. See also [1mgit-diff[22m(1) [1m--find-renames[22m.

           rename-threshold=<n>
               Deprecated synonym for [1mfind-renames=<n>[22m.

           subtree[=<path>]
               This option is a more advanced form of [4msubtree[24m strategy, where the strategy makes a guess on how two trees must be shifted to match with each other
               when merging. Instead, the specified path is prefixed (or stripped from the beginning) to make the shape of two trees to match.

       recursive
           This can only resolve two heads using a 3-way merge algorithm. When there is more than one common ancestor that can be used for 3-way merge, it creates
           a merged tree of the common ancestors and uses that as the reference tree for the 3-way merge. This has been reported to result in fewer merge
           conflicts without causing mismerges by tests done on actual merge commits taken from Linux 2.6 kernel development history. Additionally this can detect
           and handle merges involving renames. It does not make use of detected copies. This was the default strategy for resolving two heads from Git v0.99.9k
           until v2.33.0.

           The [4mrecursive[24m strategy takes the same options as [4mort[24m. However, there are three additional options that [4mort[24m ignores (not documented above) that are
           potentially useful with the [4mrecursive[24m strategy:

           patience
               Deprecated synonym for [1mdiff-algorithm=patience[22m.

           diff-algorithm=[patience|minimal|histogram|myers]
               Use a different diff algorithm while merging, which can help avoid mismerges that occur due to unimportant matching lines (such as braces from
               distinct functions). See also [1mgit-diff[22m(1) [1m--diff-algorithm[22m. Note that [1mort [22mspecifically uses [1mdiff-algorithm=histogram[22m, while [1mrecursive [22mdefaults to
               the [1mdiff.algorithm [22mconfig setting.

           no-renames
               Turn off rename detection. This overrides the [1mmerge.renames [22mconfiguration variable. See also [1mgit-diff[22m(1) [1m--no-renames[22m.

       resolve
           This can only resolve two heads (i.e. the current branch and another branch you pulled from) using a 3-way merge algorithm. It tries to carefully
           detect criss-cross merge ambiguities. It does not handle renames.

       octopus
           This resolves cases with more than two heads, but refuses to do a complex merge that needs manual resolution. It is primarily meant to be used for
           bundling topic branch heads together. This is the default merge strategy when pulling or merging more than one branch.

       ours
           This resolves any number of heads, but the resulting tree of the merge is always that of the current branch head, effectively ignoring all changes from
           all other branches. It is meant to be used to supersede old development history of side branches. Note that this is different from the -Xours option to
           the [4mrecursive[24m merge strategy.

       subtree
           This is a modified [1mort [22mstrategy. When merging trees A and B, if B corresponds to a subtree of A, B is first adjusted to match the tree structure of A,
           instead of reading the trees at the same level. This adjustment is also done to the common ancestor tree.

       With the strategies that use 3-way merge (including the default, [4mort[24m), if a change is made on both branches, but later reverted on one of the branches,
       that change will be present in the merged result; some people find this behavior confusing. It occurs because only the heads and the merge base are
       considered when performing a merge, not the individual commits. The merge algorithm therefore considers the reverted change as no change at all, and
       substitutes the changed version instead.

[1mNOTES[0m
       You should understand the implications of using [1mgit rebase [22mon a repository that you share. See also RECOVERING FROM UPSTREAM REBASE below.

       When the rebase is run, it will first execute a [1mpre-rebase [22mhook if one exists. You can use this hook to do sanity checks and reject the rebase if it isn’t
       appropriate. Please see the template [1mpre-rebase [22mhook script for an example.

       Upon completion, [1m<branch> [22mwill be the current branch.

[1mINTERACTIVE MODE[0m
       Rebasing interactively means that you have a chance to edit the commits which are rebased. You can reorder the commits, and you can remove them (weeding
       out bad or otherwise unwanted patches).

       The interactive mode is meant for this type of workflow:

        1. have a wonderful idea

        2. hack on the code

        3. prepare a series for submission

        4. submit

       where point 2. consists of several instances of

       a) regular use

        1. finish something worthy of a commit

        2. commit

       b) independent fixup

        1. realize that something does not work

        2. fix that

        3. commit it

       Sometimes the thing fixed in b.2. cannot be amended to the not-quite perfect commit it fixes, because that commit is buried deeply in a patch series. That
       is exactly what interactive rebase is for: use it after plenty of "a"s and "b"s, by rearranging and editing commits, and squashing multiple commits into
       one.

       Start it with the last commit you want to retain as-is:

           git rebase -i <after-this-commit>

       An editor will be fired up with all the commits in your current branch (ignoring merge commits), which come after the given commit. You can reorder the
       commits in this list to your heart’s content, and you can remove them. The list looks more or less like this:

           pick deadbee The oneline of this commit
           pick fa1afe1 The oneline of the next commit
           ...

       The oneline descriptions are purely for your pleasure; [4mgit[24m [4mrebase[24m will not look at them but at the commit names ("deadbee" and "fa1afe1" in this example),
       so do not delete or edit the names.

       By replacing the command "pick" with the command "edit", you can tell [1mgit rebase [22mto stop after applying that commit, so that you can edit the files and/or
       the commit message, amend the commit, and continue rebasing.

       To interrupt the rebase (just like an "edit" command would do, but without cherry-picking any commit first), use the "break" command.

       If you just want to edit the commit message for a commit, replace the command "pick" with the command "reword".

       To drop a commit, replace the command "pick" with "drop", or just delete the matching line.

       If you want to fold two or more commits into one, replace the command "pick" for the second and subsequent commits with "squash" or "fixup". If the commits
       had different authors, the folded commit will be attributed to the author of the first commit. The suggested commit message for the folded commit is the
       concatenation of the first commit’s message with those identified by "squash" commands, omitting the messages of commits identified by "fixup" commands,
       unless "fixup -c" is used. In that case the suggested commit message is only the message of the "fixup -c" commit, and an editor is opened allowing you to
       edit the message. The contents (patch) of the "fixup -c" commit are still incorporated into the folded commit. If there is more than one "fixup -c" commit,
       the message from the final one is used. You can also use "fixup -C" to get the same behavior as "fixup -c" except without opening an editor.

       [1mgit rebase [22mwill stop when "pick" has been replaced with "edit" or when a command fails due to merge errors. When you are done editing and/or resolving
       conflicts you can continue with [1mgit rebase --continue[22m.

       For example, if you want to reorder the last 5 commits, such that what was [1mHEAD~4 [22mbecomes the new [1mHEAD[22m. To achieve that, you would call [1mgit rebase [22mlike
       this:

           $ git rebase -i HEAD~5

       And move the first patch to the end of the list.

       You might want to recreate merge commits, e.g. if you have a history like this:

                      X
                       \
                    A---M---B
                   /
           ---o---O---P---Q

       Suppose you want to rebase the side branch starting at "A" to "Q". Make sure that the current [1mHEAD [22mis "B", and call

           $ git rebase -i -r --onto Q O

       Reordering and editing commits usually creates untested intermediate steps. You may want to check that your history editing did not break anything by
       running a test, or at least recompiling at intermediate points in history by using the "exec" command (shortcut "x"). You may do so by creating a todo list
       like this one:

           pick deadbee Implement feature XXX
           fixup f1a5c00 Fix to feature XXX
           exec make
           pick c0ffeee The oneline of the next commit
           edit deadbab The oneline of the commit after
           exec cd subdir; make test
           ...

       The interactive rebase will stop when a command fails (i.e. exits with non-0 status) to give you an opportunity to fix the problem. You can continue with
       [1mgit rebase --continue[22m.

       The "exec" command launches the command in a shell (the one specified in [1m$SHELL[22m, or the default shell if [1m$SHELL [22mis not set), so you can use shell features
       (like "cd", ">", ";" ...). The command is run from the root of the working tree.

           $ git rebase -i --exec "make test"

       This command lets you check that intermediate commits are compilable. The todo list becomes like that:

           pick 5928aea one
           exec make test
           pick 04d0fda two
           exec make test
           pick ba46169 three
           exec make test
           pick f4593f9 four
           exec make test

[1mSPLITTING COMMITS[0m
       In interactive mode, you can mark commits with the action "edit". However, this does not necessarily mean that [1mgit rebase [22mexpects the result of this edit
       to be exactly one commit. Indeed, you can undo the commit, or you can add other commits. This can be used to split a commit into two:

       •   Start an interactive rebase with [1mgit rebase -i <commit>^[22m, where [1m<commit> [22mis the commit you want to split. In fact, any commit range will do, as long as
           it contains that commit.

       •   Mark the commit you want to split with the action "edit".

       •   When it comes to editing that commit, execute [1mgit reset HEAD^[22m. The effect is that the [1mHEAD [22mis rewound by one, and the index follows suit. However, the
           working tree stays the same.

       •   Now add the changes to the index that you want to have in the first commit. You can use [1mgit add [22m(possibly interactively) or [1mgit gui [22m(or both) to do
           that.

       •   Commit the now-current index with whatever commit message is appropriate now.

       •   Repeat the last two steps until your working tree is clean.

       •   Continue the rebase with [1mgit rebase --continue[22m.

       If you are not absolutely sure that the intermediate revisions are consistent (they compile, pass the testsuite, etc.) you should use [1mgit stash [22mto stash
       away the not-yet-committed changes after each commit, test, and amend the commit if fixes are necessary.

[1mRECOVERING FROM UPSTREAM REBASE[0m
       Rebasing (or any other form of rewriting) a branch that others have based work on is a bad idea: anyone downstream of it is forced to manually fix their
       history. This section explains how to do the fix from the downstream’s point of view. The real fix, however, would be to avoid rebasing the upstream in the
       first place.

       To illustrate, suppose you are in a situation where someone develops a [4msubsystem[24m branch, and you are working on a [4mtopic[24m that is dependent on this
       [4msubsystem[24m. You might end up with a history like the following:

               o---o---o---o---o---o---o---o  master
                    \
                     o---o---o---o---o  subsystem
                                      \
                                       *---*---*  topic

       If [4msubsystem[24m is rebased against [4mmaster[24m, the following happens:

               o---o---o---o---o---o---o---o  master
                    \                       \
                     o---o---o---o---o       o'--o'--o'--o'--o'  subsystem
                                      \
                                       *---*---*  topic

       If you now continue development as usual, and eventually merge [4mtopic[24m to [4msubsystem[24m, the commits from [4msubsystem[24m will remain duplicated forever:

               o---o---o---o---o---o---o---o  master
                    \                       \
                     o---o---o---o---o       o'--o'--o'--o'--o'--M  subsystem
                                      \                         /
                                       *---*---*-..........-*--*  topic

       Such duplicates are generally frowned upon because they clutter up history, making it harder to follow. To clean things up, you need to transplant the
       commits on [4mtopic[24m to the new [4msubsystem[24m tip, i.e., rebase [4mtopic[24m. This becomes a ripple effect: anyone downstream from [4mtopic[24m is forced to rebase too, and so
       on!

       There are two kinds of fixes, discussed in the following subsections:

       Easy case: The changes are literally the same.
           This happens if the [4msubsystem[24m rebase was a simple rebase and had no conflicts.

       Hard case: The changes are not the same.
           This happens if the [4msubsystem[24m rebase had conflicts, or used [1m--interactive [22mto omit, edit, squash, or fixup commits; or if the upstream used one of
           [1mcommit --amend[22m, [1mreset[22m, or a full history rewriting command like [34m[1mfilter-repo[0m[1m[22m[2].

   [1mThe easy case[0m
       Only works if the changes (patch IDs based on the diff contents) on [4msubsystem[24m are literally the same before and after the rebase [4msubsystem[24m did.

       In that case, the fix is easy because [4mgit[24m [4mrebase[24m knows to skip changes that are already present in the new upstream (unless [1m--reapply-cherry-picks [22mis
       given). So if you say (assuming you’re on [4mtopic[24m)

               $ git rebase subsystem

       you will end up with the fixed history

               o---o---o---o---o---o---o---o  master
                                            \
                                             o'--o'--o'--o'--o'  subsystem
                                                              \
                                                               *---*---*  topic

   [1mThe hard case[0m
       Things get more complicated if the [4msubsystem[24m changes do not exactly correspond to the ones before the rebase.

           [1mNote[0m

           While an "easy case recovery" sometimes appears to be successful even in the hard case, it may have unintended consequences. For example, a commit that
           was removed via [1mgit rebase --interactive [22mwill be [1mresurrected[22m!

       The idea is to manually tell [1mgit rebase [22m"where the old [4msubsystem[24m ended and your [4mtopic[24m began", that is, what the old merge base between them was. You will
       have to find a way to name the last commit of the old [4msubsystem[24m, for example:

       •   With the [4msubsystem[24m reflog: after [1mgit fetch[22m, the old tip of [4msubsystem[24m is at [1msubsystem@{1}[22m. Subsequent fetches will increase the number. (See [1mgit-[0m
           [1mreflog[22m(1).)

       •   Relative to the tip of [4mtopic[24m: knowing that your [4mtopic[24m has three commits, the old tip of [4msubsystem[24m must be [1mtopic~3[22m.

       You can then transplant the old [1msubsystem..topic [22mto the new tip by saying (for the reflog case, and assuming you are on [4mtopic[24m already):

               $ git rebase --onto subsystem subsystem@{1}

       The ripple effect of a "hard case" recovery is especially bad: [4meveryone[24m downstream from [4mtopic[24m will now have to perform a "hard case" recovery too!

[1mREBASING MERGES[0m
       The interactive rebase command was originally designed to handle individual patch series. As such, it makes sense to exclude merge commits from the todo
       list, as the developer may have merged the then-current [1mmaster [22mwhile working on the branch, only to rebase all the commits onto [1mmaster [22meventually (skipping
       the merge commits).

       However, there are legitimate reasons why a developer may want to recreate merge commits: to keep the branch structure (or "commit topology") when working
       on multiple, inter-related branches.

       In the following example, the developer works on a topic branch that refactors the way buttons are defined, and on another topic branch that uses that
       refactoring to implement a "Report a bug" button. The output of [1mgit log --graph --format=%s -5 [22mmay look like this:

           *   Merge branch 'report-a-bug'
           |\
           | * Add the feedback button
           * | Merge branch 'refactor-button'
           |\ \
           | |/
           | * Use the Button class for all buttons
           | * Extract a generic Button class from the DownloadButton one

       The developer might want to rebase those commits to a newer [1mmaster [22mwhile keeping the branch topology, for example when the first topic branch is expected
       to be integrated into [1mmaster [22mmuch earlier than the second one, say, to resolve merge conflicts with changes to the DownloadButton class that made it into
       [1mmaster[22m.

       This rebase can be performed using the [1m--rebase-merges [22moption. It will generate a todo list looking like this:

           label onto

           # Branch: refactor-button
           reset onto
           pick 123456 Extract a generic Button class from the DownloadButton one
           pick 654321 Use the Button class for all buttons
           label refactor-button

           # Branch: report-a-bug
           reset refactor-button # Use the Button class for all buttons
           pick abcdef Add the feedback button
           label report-a-bug

           reset onto
           merge -C a1b2c3 refactor-button # Merge 'refactor-button'
           merge -C 6f5e4d report-a-bug # Merge 'report-a-bug'

       In contrast to a regular interactive rebase, there are [1mlabel[22m, [1mreset [22mand [1mmerge [22mcommands in addition to [1mpick [22mones.

       The [1mlabel [22mcommand associates a label with the current HEAD when that command is executed. These labels are created as worktree-local refs
       ([1mrefs/rewritten/<label>[22m) that will be deleted when the rebase finishes. That way, rebase operations in multiple worktrees linked to the same repository do
       not interfere with one another. If the [1mlabel [22mcommand fails, it is rescheduled immediately, with a helpful message how to proceed.

       The [1mreset [22mcommand resets the HEAD, index and worktree to the specified revision. It is similar to an [1mexec git reset --hard <label>[22m, but refuses to
       overwrite untracked files. If the [1mreset [22mcommand fails, it is rescheduled immediately, with a helpful message how to edit the todo list (this typically
       happens when a [1mreset [22mcommand was inserted into the todo list manually and contains a typo).

       The [1mmerge [22mcommand will merge the specified revision(s) into whatever is HEAD at that time. With [1m-C <original-commit>[22m, the commit message of the specified
       merge commit will be used. When the [1m-C [22mis changed to a lower-case [1m-c[22m, the message will be opened in an editor after a successful merge so that the user can
       edit the message.

       If a [1mmerge [22mcommand fails for any reason other than merge conflicts (i.e. when the merge operation did not even start), it is rescheduled immediately.

       By default, the [1mmerge [22mcommand will use the [1mort [22mmerge strategy for regular merges, and [1moctopus [22mfor octopus merges. One can specify a default strategy for
       all merges using the [1m--strategy [22margument when invoking rebase, or can override specific merges in the interactive list of commands by using an [1mexec [22mcommand
       to call [1mgit merge [22mexplicitly with a [1m--strategy [22margument. Note that when calling [1mgit merge [22mexplicitly like this, you can make use of the fact that the
       labels are worktree-local refs (the ref [1mrefs/rewritten/onto [22mwould correspond to the label [1monto[22m, for example) in order to refer to the branches you want to
       merge.

       Note: the first command ([1mlabel onto[22m) labels the revision onto which the commits are rebased; The name [1monto [22mis just a convention, as a nod to the [1m--onto[0m
       option.

       It is also possible to introduce completely new merge commits from scratch by adding a command of the form [1mmerge <merge-head>[22m. This form will generate a
       tentative commit message and always open an editor to let the user edit it. This can be useful e.g. when a topic branch turns out to address more than a
       single concern and wants to be split into two or even more topic branches. Consider this todo list:

           pick 192837 Switch from GNU Makefiles to CMake
           pick 5a6c7e Document the switch to CMake
           pick 918273 Fix detection of OpenSSL in CMake
           pick afbecd http: add support for TLS v1.3
           pick fdbaec Fix detection of cURL in CMake on Windows

       The one commit in this list that is not related to CMake may very well have been motivated by working on fixing all those bugs introduced by switching to
       CMake, but it addresses a different concern. To split this branch into two topic branches, the todo list could be edited like this:

           label onto

           pick afbecd http: add support for TLS v1.3
           label tlsv1.3

           reset onto
           pick 192837 Switch from GNU Makefiles to CMake
           pick 918273 Fix detection of OpenSSL in CMake
           pick fdbaec Fix detection of cURL in CMake on Windows
           pick 5a6c7e Document the switch to CMake
           label cmake

           reset onto
           merge tlsv1.3
           merge cmake

[1mCONFIGURATION[0m
       Everything below this line in this section is selectively included from the [1mgit-config[22m(1) documentation. The content is the same as what’s found there:

       rebase.backend
           Default backend to use for rebasing. Possible choices are [4mapply[24m or [4mmerge[24m. In the future, if the merge backend gains all remaining capabilities of the
           apply backend, this setting may become unused.

       rebase.stat
           Whether to show a diffstat of what changed upstream since the last rebase. False by default.

       rebase.autoSquash
           If set to true enable [1m--autosquash [22moption by default.

       rebase.autoStash
           When set to true, automatically create a temporary stash entry before the operation begins, and apply it after the operation ends. This means that you
           can run rebase on a dirty worktree. However, use with care: the final stash application after a successful rebase might result in non-trivial
           conflicts. This option can be overridden by the [1m--no-autostash [22mand [1m--autostash [22moptions of [1mgit-rebase[22m(1). Defaults to false.

       rebase.updateRefs
           If set to true enable [1m--update-refs [22moption by default.

       rebase.missingCommitsCheck
           If set to "warn", git rebase -i will print a warning if some commits are removed (e.g. a line was deleted), however the rebase will still proceed. If
           set to "error", it will print the previous warning and stop the rebase, [4mgit[24m [4mrebase[24m [4m--edit-todo[24m can then be used to correct the error. If set to
           "ignore", no checking is done. To drop a commit without warning or error, use the [1mdrop [22mcommand in the todo list. Defaults to "ignore".

       rebase.instructionFormat
           A format string, as specified in [1mgit-log[22m(1), to be used for the todo list during an interactive rebase. The format will automatically have the long
           commit hash prepended to the format.

       rebase.abbreviateCommands
           If set to true, [1mgit rebase [22mwill use abbreviated command names in the todo list resulting in something like this:

                       p deadbee The oneline of the commit
                       p fa1afe1 The oneline of the next commit
                       ...

           instead of:

                       pick deadbee The oneline of the commit
                       pick fa1afe1 The oneline of the next commit
                       ...

           Defaults to false.

       rebase.rescheduleFailedExec
           Automatically reschedule [1mexec [22mcommands that failed. This only makes sense in interactive mode (or when an [1m--exec [22moption was provided). This is the same
           as specifying the [1m--reschedule-failed-exec [22moption.

       rebase.forkPoint
           If set to false set [1m--no-fork-point [22moption by default.

       rebase.rebaseMerges
           Whether and how to set the [1m--rebase-merges [22moption by default. Can be [1mrebase-cousins[22m, [1mno-rebase-cousins[22m, or a boolean. Setting to true or to
           [1mno-rebase-cousins [22mis equivalent to [1m--rebase-merges=no-rebase-cousins[22m, setting to [1mrebase-cousins [22mis equivalent to [1m--rebase-merges=rebase-cousins[22m, and
           setting to false is equivalent to [1m--no-rebase-merges[22m. Passing [1m--rebase-merges [22mon the command line, with or without an argument, overrides any
           [1mrebase.rebaseMerges [22mconfiguration.

       rebase.maxLabelLength
           When generating label names from commit subjects, truncate the names to this length. By default, the names are truncated to a little less than [1mNAME_MAX[0m
           (to allow e.g.  [1m.lock [22mfiles to be written for the corresponding loose refs).

       sequence.editor
           Text editor used by [1mgit rebase -i [22mfor editing the rebase instruction file. The value is meant to be interpreted by the shell when it is used. It can be
           overridden by the [1mGIT_SEQUENCE_EDITOR [22menvironment variable. When not configured, the default commit message editor is used instead.

[1mGIT[0m
       Part of the [1mgit[22m(1) suite

[1mNOTES[0m
        1. revert-a-faulty-merge How-To
           file:///usr/share/doc/git/html/howto/revert-a-faulty-merge.html

        2. [1mfilter-repo[0m
           https://github.com/newren/git-filter-repo

Git 2.43.0                                                                  05/20/2024                                                               [4mGIT-REBASE[24m(1)
