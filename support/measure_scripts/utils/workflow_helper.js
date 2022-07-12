const mouse_utils = require("./mouse_utils");
const { SHARED_NAV_EXPLORE } = require("../shared/constants");

module.exports = function (context, commands, workflow) {
  const { title, description } = workflow;
  const { webdriver, driver } = context.selenium;
  let stopwatches = new Map();
  let totalScreenshots = 0;

  commands.meta.setTitle(title);
  commands.meta.setDescription(description);

  const click = async (css_path) => {
    await mouse_utils.moveToAndClickElement(
      css_path,
      commands,
      context,
      driver,
      webdriver
    );
    await screenshot();
  };

  const reset = async () => {
    await commands.navigate(`${workflow.baseURL}/${SHARED_NAV_EXPLORE}`);
    await commands.js.run(
      'document.body.innerHTML = ""; document.body.style.backgroundColor = "white";'
    );
  };

  const registerStopwatches = async (names) => {
    names.forEach((name) => {
      stopwatches.set(name, commands.stopWatch.get(name));
    });
    await screenshot();
  };

  const screenshot = async () => {
    totalScreenshots += 1;
    await commands.screenshot.take(`step${totalScreenshots}`);
  };

  const stopwatchStop = async (name) => {
    stopwatches.set(name, stopwatches.get(name).stop());
    await screenshot();
  };

  const report = async () => {
    await commands.measure.stop();

    for (let name of stopwatches.keys()) {
      commands.measure.add(name, stopwatches.get(name));
    }
  };

  return {
    reset,
    click,
    registerStopwatches,
    screenshot,
    stopwatchStop,
    report,
  };
};
