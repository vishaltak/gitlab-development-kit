const injectFakeMouseCursor = async (commands) => {
  const exists = await commands.js.run(
    'return (document.body == null || document.getElementById("selenium_mouse_follower") != null)'
  );
  if (!exists) {
    await commands.js.run(
      "var seleniumFollowerImg = document.createElement('img');seleniumFollowerImg.setAttribute('src', 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAeCAQAAACGG/bgAAAAAmJLR0QA/4ePzL8AAAAJcEhZcwAAHsYAAB7GAZEt8iwAAAAHdElNRQfgAwgMIwdxU/i7AAABZklEQVQ4y43TsU4UURSH8W+XmYwkS2I09CRKpKGhsvIJjG9giQmliHFZlkUIGnEF7KTiCagpsYHWhoTQaiUUxLixYZb5KAAZZhbunu7O/PKfe+fcA+/pqwb4DuximEqXhT4iI8dMpBWEsWsuGYdpZFttiLSSgTvhZ1W/SvfO1CvYdV1kPghV68a30zzUWZH5pBqEui7dnqlFmLoq0gxC1XfGZdoLal2kea8ahLoqKXNAJQBT2yJzwUTVt0bS6ANqy1gaVCEq/oVTtjji4hQVhhnlYBH4WIJV9vlkXLm+10R8oJb79Jl1j9UdazJRGpkrmNkSF9SOz2T71s7MSIfD2lmmfjGSRz3hK8l4w1P+bah/HJLN0sys2JSMZQB+jKo6KSc8vLlLn5ikzF4268Wg2+pPOWW6ONcpr3PrXy9VfS473M/D7H+TLmrqsXtOGctvxvMv2oVNP+Av0uHbzbxyJaywyUjx8TlnPY2YxqkDdAAAAABJRU5ErkJggg==');seleniumFollowerImg.setAttribute('id', 'selenium_mouse_follower');seleniumFollowerImg.setAttribute('style', 'position: absolute; z-index: 99999999999; pointer-events: none;');document.body.appendChild(seleniumFollowerImg);"
    );

    await commands.js.run(
      "document.onmousemove = function(e) {   const mousePointer = document.getElementById('selenium_mouse_follower');  mousePointer.style.left = e.pageX + 'px';    mousePointer.style.top = e.pageY + 'px';  }"
    );
  }
};

const moveToAndClickElement = async (selector, commands, context, driver, webdriver) => {
  await injectFakeMouseCursor(commands);

  try {
    await commands.wait.bySelector(selector);

    await injectFakeMouseCursor(commands);

    const actions = driver.actions({ async: true });
    const selected = await driver.findElement(webdriver.By.css(selector));

    await commands.wait.byTime(100); 

    console.log('CLICK SIMULATION FOR - ' + selector);   
    await commands.js.run("document.querySelector('" + selector + "').scrollIntoViewIfNeeded();");

    await actions.move({ origin: selected }).perform();
    await commands.js.run("if (document.querySelector('.gl-tooltip')) document.querySelector('.gl-tooltip').style.display = 'none';"); // tooltips from other elements can sometimes get in the way of click simulations
    await actions.pause(300).click(selected).perform();

    const url = await commands.js.run('return window.location.href');
    context.log.info(`We ended up on ${url}`);
    
    return;
  } catch(e) {
    context.log.error('Could not click on - ' + selector + ' - ', e);
    const afterContent = await commands.js.run('return document.body.innerHTML');
    context.log.info(`After Error Content ${afterContent}`);

    await commands.screenshot.take('failedclick');
  }
};

module.exports = { injectFakeMouseCursor, moveToAndClickElement };
