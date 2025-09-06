const { chromium } = require('playwright');

async function testPlaywrightCloud() {
    console.log('🎭 Testing Playwright Cloud on Killercoda');
    console.log('==========================================');
    
    // Get WebSocket endpoint from environment or use default
    const wsEndpoint = process.env.PW_TEST_CONNECT_WS_ENDPOINT || 'ws://localhost:3000/';
    console.log(`🔌 Connecting to: ${wsEndpoint}`);
    
    try {
        // Connect to remote Playwright server
        console.log('🌐 Connecting to remote browser...');
        const browser = await chromium.connect(wsEndpoint);
        
        console.log('✅ Connected successfully!');
        
        // Create a new page
        const page = await browser.newPage();
        
        // Test 1: Basic navigation
        console.log('🧪 Test 1: Basic navigation to Wikipedia...');
        await page.goto('https://www.wikipedia.org/');
        const title = await page.title();
        console.log(`📄 Page title: ${title}`);
        
        // Test 2: Search functionality
        console.log('🧪 Test 2: Testing search functionality...');
        await page.fill('input#searchInput', 'Kubernetes');
        await page.press('input#searchInput', 'Enter');
        
        // Wait for results
        await page.waitForSelector('#firstHeading', { timeout: 10000 });
        const heading = await page.textContent('#firstHeading');
        console.log(`🔍 Search result heading: ${heading}`);
        
        // Test 3: Take screenshot (to demonstrate artifact generation)
        console.log('🧪 Test 3: Taking screenshot...');
        await page.screenshot({ path: 'killercoda-test-screenshot.png' });
        console.log('📸 Screenshot saved as killercoda-test-screenshot.png');
        
        // Test 4: Multiple tabs simulation
        console.log('🧪 Test 4: Testing multiple tabs...');
        const page2 = await browser.newPage();
        await page2.goto('https://github.com');
        const page2Title = await page2.title();
        console.log(`📄 Second tab title: ${page2Title}`);
        
        // Cleanup
        await page.close();
        await page2.close();
        await browser.close();
        
        console.log('');
        console.log('🎉 All tests completed successfully!');
        console.log('✅ Playwright Cloud on Killercoda is working perfectly!');
        
    } catch (error) {
        console.error('❌ Test failed:', error.message);
        console.error('');
        console.error('🔧 Troubleshooting tips:');
        console.error('1. Make sure the Playwright server is running:');
        console.error('   kubectl get pods -n playwright-cloud');
        console.error('2. Check if port-forward is active:');
        console.error('   kubectl port-forward -n playwright-cloud service/pw-server 3000:3000');
        console.error('3. Verify the WebSocket endpoint:');
        console.error('   echo $PW_TEST_CONNECT_WS_ENDPOINT');
        process.exit(1);
    }
}

// Run the test
testPlaywrightCloud();
