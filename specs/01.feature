# Target: src/config.py
Feature: Configuration Constants

  Scenario: Expose keybindings and styling constants
    Given the Config class is defined
    Then CTRL_Q must equal integer 17
    And CTRL_S must equal integer 19
    And ESC must equal integer 27
    And COLOR_PAIR_DEFAULT must equal tuple (7, 0)
