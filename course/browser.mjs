// Starts the Chromium that playwright-core installs (`pnpm exec playwright-core install chromium`), or CHROME_PATH if set.
import {chromium} from 'playwright-core';
export const launch=(options={})=>chromium.launch({...options,...(process.env.CHROME_PATH?{executablePath:process.env.CHROME_PATH}:{})});
