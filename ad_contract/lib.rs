#![cfg_attr(not(feature = "std"), no_std, no_main)]

#[ink::contract]
mod ad_contract {
    use ink::storage::Mapping;
    use ink::storage::traits::StorageLayout;

    #[ink(storage)]
    pub struct AdContract {
        ads: Mapping<AccountId, Ad>,
        admin: AccountId,
    }

    #[derive(scale::Decode, scale::Encode, Clone, Debug, PartialEq)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo, StorageLayout))]
    pub struct Ad {
        total_amount: Balance,
        amount_per_click: Balance,
    }

    #[ink(event)]
    pub struct AdCreated {
        #[ink(topic)]
        advertiser: AccountId,
        total_amount: Balance,
        amount_per_click: Balance,
    }

    #[ink(event)]
    pub struct Rewarded {
        #[ink(topic)]
        user: AccountId,
        amount: Balance,
    }

    #[derive(scale::Decode, scale::Encode, Debug, PartialEq)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub enum Error {
        InsufficientFunds,
        AdDoesNotExist,
        NotAdmin,
    }

    impl AdContract {
        #[ink(constructor)]
        pub fn new() -> Self {
            Self {
                ads: Mapping::default(),
                admin: Self::env().caller(),
            }
        }

        #[ink(message, payable)]
        pub fn create_ad(&mut self, amount_per_click: Balance) -> Result<(), Error> {
            let caller = self.env().caller();
            let total_amount = self.env().transferred_value();

            if total_amount == 0 || amount_per_click == 0 {
                return Err(Error::InsufficientFunds);
            }

            let ad = Ad {
                total_amount,
                amount_per_click,
            };

            self.ads.insert(caller, &ad);

            self.env().emit_event(AdCreated {
                advertiser: caller,
                total_amount,
                amount_per_click,
            });

            Ok(())
        }

        #[ink(message)]
        pub fn reward(&mut self, advertiser: AccountId, user: AccountId) -> Result<(), Error> {
            if self.env().caller() != self.admin {
                return Err(Error::NotAdmin);
            }

            let mut ad = self.ads.get(&advertiser).ok_or(Error::AdDoesNotExist)?;

            if ad.total_amount < ad.amount_per_click {
                return Err(Error::InsufficientFunds);
            }

            ad.total_amount = ad.total_amount.checked_sub(ad.amount_per_click).ok_or(Error::InsufficientFunds)?;
            self.ads.insert(advertiser, &ad);

            self.env().transfer(user, ad.amount_per_click).unwrap();

            self.env().emit_event(Rewarded {
                user,
                amount: ad.amount_per_click,
            });

            Ok(())
        }

        #[ink(message)]
        pub fn get_ad(&self, advertiser: AccountId) -> Option<Ad> {
            self.ads.get(&advertiser)
        }
    }

    #[cfg(test)]
    mod tests {
        use super::*;
        use ink::env::{test, DefaultEnvironment};

        #[ink::test]
        fn create_ad_works() {
            let mut contract = AdContract::new();
            let accounts = test::default_accounts::<DefaultEnvironment>();

            let total_amount = 1000;
            let amount_per_click = 10;

            test::set_caller::<DefaultEnvironment>(accounts.alice);
            test::set_value_transferred::<DefaultEnvironment>(total_amount);

            assert!(contract.create_ad(amount_per_click).is_ok());

            let ad = contract.get_ad(accounts.alice).unwrap();
            assert_eq!(ad.total_amount, total_amount);
            assert_eq!(ad.amount_per_click, amount_per_click);
        }


        #[ink::test]
        fn reward_works() {
            let accounts = test::default_accounts::<DefaultEnvironment>();
            test::set_caller::<DefaultEnvironment>(accounts.eve);
            let mut contract = AdContract::new();
    
            // Create an ad
            test::set_caller::<DefaultEnvironment>(accounts.alice);
            test::set_value_transferred::<DefaultEnvironment>(1000);
            contract.create_ad(10).unwrap();

            let bob_balance = ink::env::test::get_account_balance::<DefaultEnvironment>(accounts.bob).unwrap();
            // Reward a user
            test::set_caller::<DefaultEnvironment>(accounts.eve); // admin
            assert!(contract.reward(accounts.alice, accounts.bob).is_ok());
    
            // Check the ad's remaining balance
            let ad = contract.get_ad(accounts.alice).unwrap();
            assert_eq!(ad.total_amount, 990);
    
            // Check Bob's balance
            let bob_balance_after = ink::env::test::get_account_balance::<DefaultEnvironment>(accounts.bob).unwrap();
            assert_eq!(bob_balance_after, bob_balance + 10);
        }

        #[ink::test]
        fn only_admin_can_reward() {
            let mut contract = AdContract::new();
            let accounts = test::default_accounts::<DefaultEnvironment>();

            // Create an ad
            test::set_caller::<DefaultEnvironment>(accounts.alice);
            test::set_value_transferred::<DefaultEnvironment>(1000);
            contract.create_ad(10).unwrap();

            // Try to reward as non-admin
            test::set_caller::<DefaultEnvironment>(accounts.bob);
            assert_eq!(contract.reward(accounts.alice, accounts.bob), Err(Error::NotAdmin));
        }
    }
}
