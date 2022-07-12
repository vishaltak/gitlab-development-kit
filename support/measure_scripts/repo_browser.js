const sourceCodeRepoWorkflow = require("./shared/sourcecode_repo");

module.exports = async function (context, commands) {
  return sourceCodeRepoWorkflow(context, commands, {
    workflow: {
      baseURL: "https://gitlab.com",
      baseRepo: "/gitlab-org/gitlab",
      branch: "master",
      title: "Test Repository Browser Workflows",
      description:
        "Tests the workflow of loading a project and then clicking through to a file 2 directories deep",
      journeyName: "RepoJourney",
    },
    stopwatches: {
      dir1Loaded: "DirectorySpecLoaded",
      dir2Loaded: "DirectoryFrontendLoaded",
      file1Loaded: "FileSpecAlertHandlerLoaded",
      dir1LoadedAgain: "DirectoryFrontendAgainLoaded",
      file2Loaded: "FileSpecApiLoaded",
    },
    navigation: {
      dir1: "spec",
      dir2: "frontend",
      file1: "alert_handler_spec.js",
      file2: "api_spec.js",
    },
    selectors: {
      selector1: "#L1",
      selector2: "#L33",
    },
  });
};
