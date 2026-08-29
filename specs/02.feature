# Target: src/buffer.py
Feature: Text Buffer State and Operations

  Scenario: Initialize empty buffer
    When TextBuffer is instantiated with path = None
    Then lines must be initialized to [""]
    And cursor_x must be 0
    And cursor_y must be 0
    And filename must be None

  Scenario: Initialize buffer with existing file
    Given a file exists on disk at path with text content
    When TextBuffer is instantiated with path
    Then lines must contain file content split by '\n'
    And filename must equal path

  Scenario: Insert normal character
    Given cursor_x is 5 and cursor_y is 0 on line "Hello"
    When insert("!") is called
    Then line 0 becomes "Hello!"
    And cursor_x increases to 6

  Scenario: Insert newline character
    Given cursor_x is 5 and cursor_y is 0 on line "Hello World"
    When insert("\n") is called
    Then line 0 is split to "Hello"
    And a new line " World" is created at line index 1
    And cursor_y becomes 1
    And cursor_x becomes 0

  Scenario: Delete character inside line
    Given cursor_x is 5 and cursor_y is 0 on line "Hello"
    When delete() is called
    Then line 0 becomes "Hell"
    And cursor_x decreases to 4

  Scenario: Delete at line start (Line merge)
    Given cursor_y is 1, cursor_x is 0, line 0 is "Hello", line 1 is "World"
    When delete() is called
    Then line 0 becomes "HelloWorld"
    And line 1 is removed from lines
    And cursor_y becomes 0
    And cursor_x becomes 5

  Scenario: Move cursor bounded
    When move_cursor(dx, dy) is called
    Then cursor_y is updated by dy bounded in [0, len(lines) - 1]
    And cursor_x is updated by dx bounded in [0, len(lines[cursor_y])]

  Scenario: Save buffer to file
    When save(path) is called
    Then target is path if provided, else self.filename
    And lines joined by '\n' are written to disk using utf-8
    And self.filename is updated to target
