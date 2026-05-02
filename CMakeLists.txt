CU_SET_PATH("CMAKE_MOD_REAGENT_BANK_ACCOUNT_DIR" "${CMAKE_CURRENT_LIST_DIR}")

AC_ADD_SCRIPT("${CMAKE_CURRENT_LIST_DIR}/src/ReagentBankAccount.cpp")
AC_ADD_SCRIPT_LOADER("ReagentBankAccount" "${CMAKE_CURRENT_LIST_DIR}/src/ReagentBankAccount_loader.cpp")

AC_ADD_CONFIG_FILE("${CMAKE_CURRENT_LIST_DIR}/conf/mod_reagent_bank_account.conf.dist")
