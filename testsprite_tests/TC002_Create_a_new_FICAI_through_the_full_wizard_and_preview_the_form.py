import asyncio
import re
from playwright import async_api
from playwright.async_api import expect

async def run_test():
    pw = None
    browser = None
    context = None

    try:
        # Start a Playwright session in asynchronous mode
        pw = await async_api.async_playwright().start()

        # Launch a Chromium browser in headless mode with custom arguments
        browser = await pw.chromium.launch(
            headless=True,
            args=[
                "--window-size=1280,720",
                "--disable-dev-shm-usage",
                "--ipc=host",
                "--single-process"
            ],
        )

        # Create a new browser context (like an incognito window)
        context = await browser.new_context()
        # Wider default timeout to match the agent's DOM-stability budget;
        # auto-waiting Playwright APIs (expect, locator.wait_for) inherit this.
        context.set_default_timeout(15000)

        # Open a new page in the browser context
        page = await context.new_page()

        # Interact with the page elements to simulate user flow
        # -> navigate
        await page.goto("http://localhost:3000/")
        try:
            await page.wait_for_load_state("domcontentloaded", timeout=5000)
        except Exception:
            pass
        
        # -> Reload the portal root page and wait for the login form (labels 'Email' and 'Password') to appear.
        await page.goto("http://localhost:3000/")
        try:
            await page.wait_for_load_state("domcontentloaded", timeout=5000)
        except Exception:
            pass
        
        # -> Click the '+ Nova FICAI' button to start a new FICAI registration.
        # Nova FICAI button
        elem = page.get_by_text('Dashboard FICAI', exact=True).locator("xpath=ancestor-or-self::*[.//button][1]").get_by_role('button', name='Nova FICAI', exact=True)
        await elem.click(timeout=10000)
        
        # -> Click the 'Carregar exemplo' button to populate the form and start the FICAI registration.
        # Carregar exemplo button
        elem = page.locator('[id="loadDemo"]')
        await elem.click(timeout=10000)
        
        # -> Click the 'Próximo' button to go to 'Situação escolar'.
        # Próximo button
        elem = page.locator('[id="btnWizardNext"]')
        await elem.click(timeout=10000)
        
        # -> Click the 'Próximo' button labeled 'Próximo' to advance to the 'Situação escolar' step.
        # Próximo button
        elem = page.locator('[id="btnWizardNext"]')
        await elem.click(timeout=10000)
        
        # -> Open the 'Escola' dropdown and select a school (start by opening the 'Escola' dropdown).
        # Selecione... C.M Teresinha de Jesus Campos de... dropdown
        elem = page.locator('[id="escola"]')
        await elem.click(timeout=10000)
        
        # -> Select the 'Escola' dropdown and choose the school option 'E. E. M. Camilo Cuquejo'.
        # Selecione... C.M Teresinha de Jesus Campos de... dropdown
        elem = page.locator("xpath=/html/body/div[2]/div/main/section[2]/form/section/div[2]/div/div[3]/select").nth(0)
        await elem.wait_for(state="visible", timeout=10000)
        await elem.select_option("")
        
        # -> Fill the 'Turma' field and set the absence period (Período de ausência) by locating those inputs on the Etapa 1 form.
        await page.mouse.wheel(0, 300)
        
        # -> Scroll the 'Etapa 1 — Escola e aluno' form to reveal the 'Turma' and 'Período de ausência' inputs so they can be filled.
        await page.mouse.wheel(0, 300)
        
        # -> Scroll the 'Etapa 1 de 6 — Escola e aluno' form down to reveal the 'Turma' and 'Período de ausência' inputs so they can be filled.
        await page.mouse.wheel(0, 300)
        
        # -> Scroll the form to reveal the 'Período de ausência' and 'Turma' fields and locate their input controls.
        await page.mouse.wheel(0, 300)
        
        # -> Locate the 'Período de ausência' field on the Etapa 1 — Escola e aluno form so it can be filled.
        await page.mouse.wheel(0, 300)
        
        # --> Assertions to verify final state
        
        # --> The Gerar FICAI wizard is on Etapa 1 — 'Escola e aluno' and demo data was loaded into the form.
        await page.locator("xpath=/html/body/div[2]/div/main/section[2]/div[2]/div/button[1]").nth(0).scroll_into_view_if_needed()
        # Assert-outcome: passed
        # Assert: Etapa 1 — 'Escola e aluno' tab is visible.
        await expect(page.locator("xpath=/html/body/div[2]/div/main/section[2]/div[2]/div/button[1]").nth(0)).to_be_visible(timeout=15000), "Etapa 1 \u2014 'Escola e aluno' tab is visible."
        # Assert-outcome: passed
        # Assert: The student name field contains the demo name.
        await expect(page.locator("xpath=/html/body/div[2]/div/main/section[2]/form/section[1]/div[2]/div[3]/div[2]/input").nth(0)).to_have_value("Aluno Demonstrativo", timeout=15000), "The student name field contains the demo name."
        await asyncio.sleep(5)

    finally:
        if context:
            await context.close()
        if browser:
            await browser.close()
        if pw:
            await pw.stop()

asyncio.run(run_test())
    