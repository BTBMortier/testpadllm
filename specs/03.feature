# Target: src/ui.py
Feature: Terminal UI Rendering and Input Handling

  Scenario: TerminalUI Initialization
    When TerminalUI is instantiated with stdscr
    Then curses.noecho() is called
    And curses.cbreak() is called
    And stdscr.keypad(True) is called
    And curses.curs_set(1) is called

  Scenario: Render screen securely
    Given terminal bounds max_y and max_x from self.stdscr.getmaxyx()
    When render(buffer) is called
    Then self.stdscr.clear() is called
    And lines up to max_y - 1 are displayed, truncated at max_x - 1
    And system cursor is set to (min(buffer.cursor_y, max_y - 1), min(buffer.cursor_x, max_x - 1))
    And self.stdscr.refresh() is called

  Scenario: Key Input Routing
    When handle_input(buffer) reads key from self.stdscr.getch()
    Then key 17 (Config.CTRL_Q) returns False
    And key 19 (Config.CTRL_S) calls buffer.save() and returns True
    And key in (curses.KEY_BACKSPACE, 127, 8) calls buffer.delete() and returns True
    And key in (10, 13, curses.KEY_ENTER) calls buffer.insert('\n') and returns True
    And key curses.KEY_LEFT calls buffer.move_cursor(-1, 0) and returns True
    And key curses.KEY_RIGHT calls buffer.move_cursor(1, 0) and returns True
    And key curses.KEY_UP calls buffer.move_cursor(0, -1) and returns True
    And key curses.KEY_DOWN calls buffer.move_cursor(0, 1) and returns True
    And key in range 32 to 126 calls buffer.insert(chr(key)) and returns True
    And unhandled keys return True without side effects
