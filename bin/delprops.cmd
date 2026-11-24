@echo off
rem Executa a linha de comando do DelProps.
rem Uso: delprops ^<comando^> [argumentos]
if "%DELPROPS_DELEGUA%"=="" (set DELPROPS_DELEGUA=delegua)
%DELPROPS_DELEGUA% "%~dp0..\fontes\ilc.delegua" -- %*
