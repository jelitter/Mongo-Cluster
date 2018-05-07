@echo off
@echo ### Loop test
FOR /L %%A IN (1,1,10) DO (
    echo This is loop %%A
    echo Test: Cork%%A
    echo.
)