review & double check again to make sure that all ps1 file work together.
then combine them into one file "build-app-cli.ps1" and make let it run as a cli program with selectable features:
0. exit
1. start build (call build.ps1)
2. start gen (call gen-buildenv.ps1)
3. preview files: buildenv
4. clean
5. apk-converter (see "OUTPUT_PATH"=/dist folder to find aab files; also add new variables
to manage the convert like bundletoolPaths, keyPropsPath, keystorePath, aabPath)

*make sure everythings work together.