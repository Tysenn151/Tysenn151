SELECT
    SUM (SourceSystemBalance) as CurrentPeriodBalance,
    SUM (PriorSourceSystemBalance) as PriorPeriodBalance,
    SUM (SourceSystemBalance) - SUM (PriorSourceSystemBalance) AS ChangeFromPrior,
    
    (CASE
        WHEN  SUM (PriorSourceSystemBalance) = 0
        THEN NULL
        ELSE
            (
                (SUM (SourceSystemBalance) - SUM (PriorSourceSystemBalance))/ SUM (PriorSourceSystemBalance)
            )
        END
    ) AS perChangeFromPrior,
    
    SUM (UnreconcSourceSystemBalance) as UnreconciledBalance,
    SUM (UnExplainedBal) as UnExplainedBal,
    SUM (ReconcillingItemBal) as ReconcillingItemBal,
    PERIOD_NAME,
    ACCOUNT_TYPE_NAME,
    REO_RECONCILIATION_NAME,
    '~CURRENCY~' AS CURRENCY
FROM (
        SELECT
            COALESCE(BalanceSubSystem,0) AS BalanceSubSystem,
            COALESCE(ExplainedBalance,0) AS ExplainedBalance,
            COALESCE(SubSystemAdjustments,0) AS SubSystemAdjustments,
            COALESCE(PriorSourceSystemBalance,0) AS PriorSourceSystemBalance,
            COALESCE(SourceSystemBalance,0) AS SourceSystemBalance,
            COALESCE(SourceSystemAdjustments,0) AS SourceSystemAdjustments ,
            COALESCE( SourceSystemAdjustments,0) AS   ReconcillingItemBal,
        
            (CASE
                WHEN STATUS_ID = 1
                THEN 0
                ELSE COALESCE( SourceSystemBalance,0)
                END
            ) AS UnreconcSourceSystemBalance ,
        
            (CASE
                WHEN RECONCILIATION_METHOD = 'A'
                THEN COALESCE(SourceSystemBalance,0) - COALESCE(SourceSystemAdjustments,0) - COALESCE(ExplainedBalance,0)
                ELSE (COALESCE(SourceSystemBalance,0) - COALESCE(SourceSystemAdjustments,0))-(COALESCE(BalanceSubSystem,0) - COALESCE(SubSystemAdjustments,0) )
                END
            ) AS UnExplainedBal,
            
            PERIOD_NAME,
            ACCOUNT_TYPE_NAME,
            REO_RECONCILIATION_NAME
        
        FROM (
                SELECT innerSubQry.PERIOD_NAME,
                        innerSubQry.PEO_PERIOD_ID,
                        innerSubQry.PEO_PRIOR_PERIOD_ID,
                        innerSubQry.ACCOUNT_TYPE_NAME,
                        innerSubQry.ACCOUNT_TYPE_ID,
                        innerSubQry.RECONCILIATION_METHOD,
                        innerSubQry.STATUS_ID,
                        innerSubQry.REO_PERIOD_ID,
                        innerSubQry.REO_RECONCILIATION_ID,
                        innerSubQry.REO_RECONCILIATION_ACCOUNT_ID,
                        innerSubQry.REO_RECONCILIATION_NAME,  
                        innerSubQry.LIST_VALUE_ID,
                        
                        (SELECT SUM (
                                    COALESCE(BalanceSubSystem.AMOUNT,0) *        
                                    COALESCE( 
                                                (SELECT COALESCE(rate,1)
                                                FROM arm_rate_types art,
                                                        arm_currency_rates acr
                                                WHERE art.rate_type_id = acr.rate_type_id
                                                  AND acr.rate_type_id  = ~RATE_TYPE~
                                                  AND acr.PERIOD_ID = innerSubQry.REO_PERIOD_ID
                                                  AND acr.FROM_CURRENCY = BalanceSubSystem.CURRENCY
                                                  AND acr.TO_CURRENCY   = '~CURRENCY~')
                                            ,1)
                                    )
                           FROM ARM_BALANCES BalanceSubSystem
                          WHERE innerSubQry.REO_RECONCILIATION_ACCOUNT_ID = BalanceSubSystem.PROFILE_ID
                            AND BalanceSubSystem.BUCKET_ID    = ~CURRENCY_BUCKET~
                            AND BalanceSubSystem.PERIOD_ID = innerSubQry.PEO_PERIOD_ID
                            AND BalanceSubSystem.BALANCE_TYPE = 2
                           ) AS BalanceSubSystem,

                        (SELECT SUM (
                                    COALESCE(SourceSystemBalance.AMOUNT,0) *  
                                    COALESCE( 
                                                (SELECT COALESCE(rate,1)
                                                FROM arm_rate_types art ,
                                                     arm_currency_rates acr
                                                WHERE art.rate_type_id    = acr.rate_type_id
                                                  AND acr.rate_type_id  = ~RATE_TYPE~
                                                  AND acr.PERIOD_ID = innerSubQry.REO_PERIOD_ID
                                                  AND acr.FROM_CURRENCY = SourceSystemBalance.CURRENCY
                                                  AND acr.TO_CURRENCY   = '~CURRENCY~')
                                            ,1)
                                    )
                            FROM ARM_BALANCES SourceSystemBalance
                           WHERE innerSubQry.REO_RECONCILIATION_ACCOUNT_ID = SourceSystemBalance.PROFILE_ID
                             AND SourceSystemBalance.BUCKET_ID    = ~CURRENCY_BUCKET~
                             AND SourceSystemBalance.PERIOD_ID = innerSubQry.PEO_PERIOD_ID
                             AND SourceSystemBalance.BALANCE_TYPE = 1 
                            ) AS SourceSystemBalance ,

                            (SELECT SUM (
                                        COALESCE(PriorSourceSystemBalance.AMOUNT,0) *
                                        COALESCE( 
                                                    (SELECT COALESCE(rate,1)
                                                    FROM arm_rate_types art ,
                                                         arm_currency_rates acr
                                                    WHERE art.rate_type_id    = acr.rate_type_id
                                                      AND acr.rate_type_id  = ~RATE_TYPE~
                                                      AND acr.PERIOD_ID = innerSubQry.REO_PERIOD_ID
                                                      AND acr.FROM_CURRENCY = PriorSourceSystemBalance.CURRENCY
                                                      AND acr.TO_CURRENCY   = '~CURRENCY~')
                                                ,1)
                                        )
                                FROM ARM_BALANCES PriorSourceSystemBalance
                                WHERE innerSubQry.REO_RECONCILIATION_ACCOUNT_ID = PriorSourceSystemBalance.PROFILE_ID
                                AND PriorSourceSystemBalance.PERIOD_ID = innerSubQry.PEO_PRIOR_PERIOD_ID
                                AND PriorSourceSystemBalance.BUCKET_ID    = ~CURRENCY_BUCKET~
                                AND PriorSourceSystemBalance.BALANCE_TYPE = 1 
                            ) AS PriorSourceSystemBalance ,

                            (SELECT SUM (
                                        COALESCE(SourceSystemAdjustments.AMOUNT,0) * 
                                        COALESCE( 
                                            (SELECT COALESCE(rate,1)
                                               FROM
                                                    arm_rate_types art ,
                                                    arm_currency_rates acr
                                              WHERE art.rate_type_id    = acr.rate_type_id
                                                AND acr.rate_type_id  = ~RATE_TYPE~
                                                AND acr.PERIOD_ID = innerSubQry.REO_PERIOD_ID
                                                AND acr.FROM_CURRENCY = SourceSystemAdjustments.CURRENCY
                                                AND acr.TO_CURRENCY   = '~CURRENCY~')
                                            ,1)
                                        )
                                 FROM ARM_TRANSACTION_SUMMARIES SourceSystemAdjustments
                                WHERE innerSubQry.REO_RECONCILIATION_ID = SourceSystemAdjustments.RECONCILIATION_ID
                                  AND SourceSystemAdjustments.CURRENCY_BUCKET_ID    = ~CURRENCY_BUCKET~
                                  AND SourceSystemAdjustments.TRANSACTION_TYPE = 'SRC'
                            ) AS SourceSystemAdjustments ,
                
                        (SELECT SUM (
                                        COALESCE(SubSystemAdjustments.AMOUNT,0) * 
                                        COALESCE( 
                                            (SELECT COALESCE(rate,1)
                                               FROM
                                                    arm_rate_types art ,
                                                    arm_currency_rates acr
                                              WHERE art.rate_type_id    = acr.rate_type_id
                                                AND acr.rate_type_id  = ~RATE_TYPE~
                                                AND acr.PERIOD_ID = innerSubQry.REO_PERIOD_ID
                                                AND acr.FROM_CURRENCY = SubSystemAdjustments.CURRENCY
                                                AND acr.TO_CURRENCY   = '~CURRENCY~')
                                            ,1)
                                        )
                                 FROM ARM_TRANSACTION_SUMMARIES SubSystemAdjustments
                                WHERE innerSubQry.REO_RECONCILIATION_ID = SubSystemAdjustments.RECONCILIATION_ID
                                  AND SubSystemAdjustments.CURRENCY_BUCKET_ID    = ~CURRENCY_BUCKET~
                                  AND SubSystemAdjustments.TRANSACTION_TYPE = 'SUB'
                            ) AS SubSystemAdjustments ,
                        
                        (SELECT SUM (
                                        COALESCE(BalanceExplanation.AMOUNT,0) * 
                                        COALESCE( 
                                            (SELECT COALESCE(rate,1)
                                               FROM
                                                    arm_rate_types art ,
                                                    arm_currency_rates acr
                                              WHERE art.rate_type_id    = acr.rate_type_id
                                                AND acr.rate_type_id  = ~RATE_TYPE~
                                                AND acr.PERIOD_ID = innerSubQry.REO_PERIOD_ID
                                                AND acr.FROM_CURRENCY = BalanceExplanation.CURRENCY
                                                AND acr.TO_CURRENCY   = '~CURRENCY~')
                                            ,1)
                                        )
                                 FROM ARM_TRANSACTION_SUMMARIES BalanceExplanation
                                WHERE innerSubQry.REO_RECONCILIATION_ID = BalanceExplanation.RECONCILIATION_ID
                                  AND BalanceExplanation.CURRENCY_BUCKET_ID    = ~CURRENCY_BUCKET~
                                  AND BalanceExplanation.TRANSACTION_TYPE = 'BEX'
                            ) AS ExplainedBalance 
                
                FROM (SELECT PeriodEO.PERIOD_NAME,
                            PeriodEO.PERIOD_ID AS PEO_PERIOD_ID,
                            PeriodEO.PRIOR_PERIOD_ID AS PEO_PRIOR_PERIOD_ID,
                            AccountTypeEO.ACCOUNT_TYPE_NAME,
                            AccountTypeEO.ACCOUNT_TYPE_ID,
                            FormatEO.RECONCILIATION_METHOD,
                            ReconciliationEO.STATUS_ID,
                            ReconciliationEO.PERIOD_ID AS REO_PERIOD_ID,
                            ReconciliationEO.RECONCILIATION_ID AS REO_RECONCILIATION_ID,
                            ReconciliationEO.RECONCILIATION_ACCOUNT_ID AS REO_RECONCILIATION_ACCOUNT_ID,
                            ReconciliationEO.RECONCILIATION_NAME AS REO_RECONCILIATION_NAME,
                            AttributeListValueEO18A.LIST_VALUE_ID
                        FROM
                            ARM_RECONCILIATIONS ReconciliationEO
                        LEFT OUTER JOIN ARM_PERIODS PeriodEO
                            ON
                            (
                                ReconciliationEO.PERIOD_ID = PeriodEO.PERIOD_ID
                            )
                        LEFT OUTER  JOIN ARM_ACCOUNT_TYPES AccountTypeEO
                            ON
                            (
                                ReconciliationEO.ACCOUNT_TYPE_ID = AccountTypeEO.ACCOUNT_TYPE_ID
                            )
                        LEFT OUTER JOIN ARM_FORMATS FormatEO
                            ON
                            (
                                ReconciliationEO.FORMAT_ID = FormatEO.FORMAT_ID
                            )
                        LEFT OUTER JOIN ARM_ATTRIBUTE_VALUES AttributeValueEO17A
                            ON
                            (
                                ReconciliationEO.RECONCILIATION_ID = AttributeValueEO17A.OBJECT_ID
                            AND AttributeValueEO17A.ATTRIBUTE_ID = 1300
                            )
                        LEFT OUTER JOIN FCM_ATTRIBUTE_LIST_VALUES AttributeListValueEO18A
                            ON
                            (
                                AttributeValueEO17A.VALUE_LIST_CHOICE_ID =
                                AttributeListValueEO18A.LIST_VALUE_ID
                            )
                        WHERE
                                    ReconciliationEO.PERIOD_ID =  ~PERIOD_ID~
                                    AND $ARM_SECURITY_CLAUSE$ 
                        ) innerSubQry

                WHERE (~RISK_RATING~ is not null and innerSubQry.LIST_VALUE_ID = ~RISK_RATING~) 
                   OR (~RISK_RATING~ is null )
        ) InnerQry 

    ) OuterQry

group by 
    Period_name ,
    ACCOUNT_TYPE_NAME,
    REO_RECONCILIATION_NAME