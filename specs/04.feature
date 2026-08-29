# Target: main.py
Feature: Main Application Entrypoint

  Scenario: Application execution lifecycle
    When Main.run() is called
    Then filename is parsed from sys.argv[1] if present, else None
    And TextBuffer is instantiated with filename
    And curses.wrapper starts event loop executing ui.render(buffer) then ui.handle_input(buffer) until handle_input returns False
