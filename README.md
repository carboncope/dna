# dna
Rotation building addon for wow

How to submit a build to website

1. Before you submit make sure you make localization changes
2. Change the .toc version file
3. Open the Git Gui and Stage Changed button, commit all lua code changes with a commit message like this:
1.0.24
bla line 1
bla line 2

4. Update the CHANGELOG.txt with the last commit, open git bash from the dna dir
git --no-pager log --decorate=short -n 1 > CHANGELOG.txt
5. Go back to the Git Gui and aclick Rescan button at bottom -> Stage Changed button and Check the Amend Last Commit, Click unlock index
6. Commit all the changes with the CHANGELOG.txt to amend last commit

7. Goto Repository -> Visualize all Branch history menu.
8. Right click the commit and select Create Tag
9. The Tag name:
1.0.24

10. The Tag message:
dna

11. Go back to the git gui and click Push button at bottom
12. Source Branch main is selected
13. Remote radio button is checked to origin
14. CHECK the include tags option
15. Click Push again