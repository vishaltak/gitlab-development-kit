const workflowHelper = require("../utils/workflow_helper");
const { MAX_WAIT_TIME } = require("../shared/constants");

module.exports = async function (context, commands, config) {
  const { workflow, stopwatches, navigation, selectors } = config;
  const helper = workflowHelper(context, commands, workflow);
  
  const clickTree = async (path) =>
    await helper.click(`a[href="${workflow.baseRepo}/-/tree/${workflow.branch}/${path}"]`);
  const clickBlob = async (path) =>
    await helper.click(`a[href="${workflow.baseRepo}/-/blob/${workflow.branch}/${path}"]`);

  // Reset display
  await helper.reset();

  await commands.navigate(workflow.baseURL + workflow.baseRepo);

  await commands.measure.start(workflow.journeyName);

  helper.registerStopwatches(Object.values(stopwatches));

  // Lets start measuring
  await clickTree(navigation.dir1);

  helper.stopwatchStop(stopwatches.dir1Loaded);

  await clickTree(`${navigation.dir1}/${navigation.dir2}`);

  helper.stopwatchStop(stopwatches.dir2Loaded);

  await clickBlob(
    `${navigation.dir1}/${navigation.dir2}/${navigation.file1}`
  );

  // Lets wait for text in the actual file
  await commands.wait.bySelector(selectors.selector1, MAX_WAIT_TIME);

  helper.stopwatchStop(stopwatches.file1Loaded);

  await clickTree(`${navigation.dir1}/${navigation.dir2}`);

  helper.stopwatchStop(stopwatches.dir1LoadedAgain);

  await clickBlob(
    `${navigation.dir1}/${navigation.dir2}/${navigation.file2}`
  );

  // Lets wait for text in the actual file
  await commands.wait.bySelector(selectors.selector2, MAX_WAIT_TIME);

  helper.stopwatchStop(stopwatches.file2Loaded);

  await commands.wait.byTime(2000);

  await helper.report();
};
