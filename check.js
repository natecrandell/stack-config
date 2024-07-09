/* script:  access services - test sso student login - ClassLink
   account: IL PRODUCTION
   description: this is intended to log into ClassLink
                using our test sso student account,
                click into the "Imagine L&L Prod" app tile,
                verifying they can view the PSS,
                and ultimately log out.
*/
var assert = require('assert');
const userNameKey = 'AXS_SSO_TEST_STUDENT_LOGIN';
const userName = $secure.AXS_SSO_TEST_STUDENT_LOGIN;

const passwordKey = 'AXS_SSO_TEST_STUDENT_LOGIN_PWD';
const password = $secure.AXS_SSO_TEST_STUDENT_LOGIN_PWD;

const tileName = 'Imagine L&L Prod';

function assertElement(step, assertType, actual, expected) {
  var expectedBoolean = (expected === 'true');
  var assertionFailureMessage = 'Step monitor failure - Failed on step #' + (step + 1) + ' - Assertion Failure - ';
  try {
    if (assertType == 'visible' && actual != null) {
      actual.isDisplayed().then(function (state) {
        assertionFailureMessage += 'Expected state: "' + expectedBoolean + '", Actual state: "' + state + '"';
        assert.equal(state, expectedBoolean, assertionFailureMessage);
      });
    } else {
      assertionFailureMessage += 'Expected state: "' + expectedBoolean + '", Actual state: "' + !!actual + '"';
      assert.equal(!!actual, expectedBoolean, assertionFailureMessage);
    }
  } catch (e) {
    throw ({ type: 'Step error', message: e.message, step: step });
  }
}

function findElement(step, selector) {
  return $browser.waitForElement($driver.By.css(selector)).then(function (e) {
    console.log('Found first element by CSS with selector: <' + selector + '>');
    return e;
  }).catch(function () {
    console.log('Element not found by CSS, trying xpath...');
    return $browser.waitForElement($driver.By.xpath(selector)).then(function (e) {
      console.log('Found first element by xpath with selector: <' + selector + '>');
      return e;
    }).catch(function () {
      console.log('Element not found by xpath, trying partial link text...');
      return $browser.waitForElement($driver.By.partialLinkText(selector)).then(function (e) {
        console.log('Found first element by partial link text with selector: <' + selector + '>');
        return e;
      }).catch(function () {
        console.log('Element not found by partial link text, trying ID...');
        return $browser.waitForElement($driver.By.id(selector)).then(function (e) {
          console.log('Found first element by ID with selector: <' + selector + '>');
          return e;
        }).catch(function () {
          throw ({ type: 'Step error', message: 'Step monitor failure - Failed on step #' + (step + 1) + ' - Could not locate element by XPath, CSS Selector, partial link text, or HTML ID - selector: <' + selector + '>', step: step, selector: selector });
        });
      });
    });
  });
}

console.log('Step ' + (0 + 1));
console.log('Navigating to "https://launchpad.classlink.com/imaginelearning"');
$browser.get('https://launchpad.classlink.com/imaginelearning')
  .then(function () {
    console.log('Step ' + (1 + 1));
    console.log('Entering secure key: "' + userNameKey + '" into element with selector: <#username>');
    $browser.waitForElement($driver.By.css('#username')).then(e => e.clear().then(() => e.sendKeys(userName)));
  })
  .then(function () {
    console.log('Step ' + (2 + 1));
    console.log('Entering secure key: "' + passwordKey + '" into element with selector: <#password>');
    $browser.waitForElement($driver.By.css('#password')).then(e => e.clear().then(() => e.sendKeys(password)));
  })
  .then(function () {
    console.log('Step ' + (3 + 1));
    console.log('Clicking on element with selector: <#signin>');
    $browser.waitForElement($driver.By.css('#signin')).then(e => e.click());
  })
  .then(function () {
    console.log('Step ' + (4 + 1));
    console.log('Clicking on element with selector: <app-apps-container application[aria-label="'+ tileName + '"]>');
    $browser.waitForElement($driver.By.css('app-apps-container application[aria-label="Imagine L&L Prod"]')).then(e => e.click());
  })
  .then(function () {
    console.log('Step ' + (5 + 1));
    console.log('Finding Product Selection Screen tab');
    $browser.getAllWindowHandles().then(windowHandlers => {
      $browser.switchTo().window(windowHandlers[1]);
      return Promise.resolve(true)
    })
    .then(function () {
      console.log('...and Clicking "Log Out"');
      $browser.waitForElement($driver.By.xpath('//button[text()="Log Out"]')).then(e => e.click());
    });
  })
  .catch(e => {
    if (e.type && e.type === 'Step error') {
      console.log(JSON.stringify(e));
    }
    throw e.message;
  });