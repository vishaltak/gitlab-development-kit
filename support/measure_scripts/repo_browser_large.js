const sourceCodeRepoWorkflow = require("./shared/sourcecode_repo");

module.exports = async function (context, commands) {
  return sourceCodeRepoWorkflow(context, commands, {
    workflow: {
      baseURL: "https://gitlab.com",
      baseRepo:
        "/gitlab-org/frontend/sitespeed-test-group/sitespeed-fixture-repo",
      branch: "main",
      title: "Test Repository Browser Workflows (Large Repository)",
      description: "Loading a project with a large directory and source files",
      journeyName: "RepoJourneyLarge",
    },
    stopwatches: {
      dir1Loaded: "DirectoryLargeLoaded",
      dir2Loaded: "DirectoryDir1000Loaded",
      file1Loaded: "FileLargeFile1Loaded",
      dir1LoadedAgain: "DirectoryLargeLoadedAgain",
      file2Loaded: "FileLargeFile2Loaded",
    },
    navigation: {
      dir1: "large_directory",
      dir2: "dir_1000",
      file1: "large_file_1.json",
      file2: "large_file_2.json",
    },
    selectors: {
      selector1: "#L1",
      selector2: "#L20000",
    },
  });
};
