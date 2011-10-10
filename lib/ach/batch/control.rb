module ACH
  # Every {ACH::Batch batch} components ends with batch control record.
  # == Fields:
  # * record_type
  # * service_class_code
  # * entry_addenda_count
  # * entry_hash
  # * total_debit_amount
  # * total_credit_amount
  # * company_id
  # * authen_code
  # * bank_6
  # * origin_dfi_id
  # * batch_number
  class Batch::Control < Record
    fields :record_type,
      :service_class_code,
      :entry_addenda_count,
      :entry_hash,
      :total_debit_amount,
      :total_credit_amount,
      :company_id,
      :authen_code,
      :bank_6,
      :origin_dfi_id,
      :batch_number
    
    defaults :record_type => 8,
      :authen_code        => '',
      :bank_6             => ''
  end
end
