import subprocess
import getpass
import sys
import time

# --- Configuration ---
WALLET_NAME = "votingWallet"

def secure_unlock():
    """Prompts for password securely and executes the Feathercoin unlock command."""
    print("--- Secure Wallet Unlock Script ---")

    # 1. Securely ask for the password without echoing it
    try:
        # Use getpass to hide the password input
        password = getpass.getpass(f"Enter password for wallet '{WALLET_NAME}': ")
    except Exception as e:
        print(f"Error during password input: {e}")
        return

    # 2. Define the unlock command
    # Unlocks for 600 seconds (10 minutes)
    unlock_time = 600
    command = [
        "./feathercoin-cli",
        # CRITICAL: Always specify the named wallet
        f"-rpcwallet={WALLET_NAME}",
        "walletpassphrase",
        password,
        str(unlock_time)
    ]

    print(f"Executing unlock command for {unlock_time} seconds...")

    # 3. Execute the command securely
    try:
        result = subprocess.run(command, capture_output=True, text=True, check=False)

        if result.returncode == 0:
            print("\n✅ Wallet UNLOCKED successfully.")
            print("You now have 10 minutes to run your administrative scripts.")
        else:
            print("\n❌ WALLET UNLOCK FAILED. Error details:")
            print(result.stderr.strip())
            print("Possible causes: Incorrect password, wallet not loaded, or Feathercoin daemon not running.")

    except FileNotFoundError:
        print("\nERROR: 'feathercoin-cli' not found. Check your PATH or run this script from the Feathercoin directory.")

# Execute the script
if __name__ == "__main__":
    secure_unlock()
 
