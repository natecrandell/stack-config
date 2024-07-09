/**
 * Script Name: Advanced Example - Chrome 100+
 * Author:      New Relic
 * Version:     1.6
 */

// -------------------- CONSTANTS
const SCRIPT_NAME = "Best Practices - Chrome 100"                        // name to record in script log
const IMPLICIT_TIMEOUT = 3000                                            // default implicit timeout is 10 seconds
const PAGE_LOAD_TIMEOUT = 60000                                          // default page load timeout is 60 seconds, fail early to prevent long duration timeouts
const SCRIPT_TIMEOUT = 20000                                             // default script timeout is 30 seconds
const USER_AGENT = "default"                                             // set the user agent for Chrome
const PROTOCOL = "https://"                                              // set the protocol
const USERNAME = ""                                                      // username:
const PASSWORD = ""                                                      // password@
const DOMAIN = "docs.newrelic.com"                                       // your domain
const PATH = "/docs/new-relic-solutions/get-started/intro-new-relic/"    // path to main page
const CHECK = "Get started with New Relic"                               // text to match on page
const AUTH = USERNAME + PASSWORD                                         // could be stored as secure credentials
const MAIN_URL = PROTOCOL + AUTH + DOMAIN + PATH

// -------------------- DEPENDENCIES
const assert = require("assert")

// -------------------- CONFIGURATION
await $webDriver.manage().setTimeouts({
  implicit: IMPLICIT_TIMEOUT,  // sets element load timeout
  pageLoad: PAGE_LOAD_TIMEOUT, // sets page load timeout
  script: SCRIPT_TIMEOUT       // sets script timeout
})

// -------------------- ELEMENTS
const By = $selenium.By
const loc = {
  title: By.css("#gatsby-focus-wrapper > div.css-1uz5ayg > div > main > div > h1"),
  start: [
    { step: 'signup',     selector: By.id("sign-up-for-new-relic-if-you-havent-already") },
    { step: 'add',        selector: By.id("add-your-data") },
    { step: 'explore',    selector: By.id("explore-your-data") },
    { step: 'query',      selector: By.id("query-your-data") },
    { step: 'dashboard',  selector: By.id("set-up-a-dashboard") },
    { step: 'alerts',     selector: By.id("configure-alerts") }
  ]
}

// -------------------- FUNCTIONS
// for backwards compatibility with legacy runtimes
async function waitForAndFindElement(locator, timeout) {
  const element = await $webDriver.wait(
    $selenium.until.elementLocated(locator),
    timeout,
    "Timed-out waiting for element to be located using: " + locator
  )
  await $webDriver.wait(
    $selenium.until.elementIsVisible(element),
    timeout,
    "Timed-out waiting for element to be visible using ${element}"
  )
  return await $webDriver.findElement(locator)
}

// -------------------- START OF SCRIPT
// Start logging
const start_time = new Date()
console.log("Starting synthetics script: " + SCRIPT_NAME)

// confirm timeouts are set
const {implicit, pageLoad, script} = await $webDriver.manage().getTimeouts()
console.log("Timeouts are set to:")
console.log("  IMPLICIT: " + implicit / 1000 + "s")
console.log("  PAGE LOAD: " + pageLoad / 1000 + "s")
console.log("  SCRIPT: " + script / 1000 + "s")

// Setting User Agent is not then-able, so we do this first (if defined and not default)
if (USER_AGENT && 0 !== USER_AGENT.trim().length && USER_AGENT != "default") {
  $headers.add("User-Agent", USER_AGENT)
  console.log("Setting User-Agent to " + USER_AGENT)
}

// if an error happens at any step, script execution is halted and a failed result is returned
console.log("1. get: " + MAIN_URL)
await $webDriver.get(MAIN_URL)

console.log("2. waitForAndFindElement: " + loc.title)
const textBlock = await waitForAndFindElement(loc.title, IMPLICIT_TIMEOUT)

console.log("3. getText: " + CHECK)
const text1 = await textBlock.getText()

console.log("4. assert.equal: " + text1)
assert.equal(text1, CHECK, "title validation text not found")

console.log("5. takeScreenshot")
await $webDriver.takeScreenshot()

console.log("6. findElement")
loc.start.forEach(async function (nr, i) {
  let n = i + 1
  try{
    // verify each asset has loaded
    console.log("  " + n + ". " + nr.step + ": " + nr.selector)
    await $webDriver.findElement(nr.selector)
  }catch(exception){
    console.error("Failure in Step 6." + n)
    throw exception
  }
})

// End logging
const end_time = new Date()

// Calculate the duration
const script_duration = (end_time - start_time) / 1000

// Log the times
console.log("Start time: " + start_time)
console.log("End time: " + end_time)
console.log("Duration: " + script_duration + "s")