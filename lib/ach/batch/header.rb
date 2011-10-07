module ACH
  # Every {ACH::Batch batch} component start with batch header record.
  # == Fields:
  # * record_type
  # * service_class_code
  # * company_name
  # * company_note_data
  # * company_id
  # * entry_class_code
  # * company_entry_descr
  # * desc_date
  # * effective_date
  # * settlement_date
  # * origin_status_code
  # * origin_dfi_id
  # * batch_number
  class Batch::Header < Record
    fields :record_type,
      :service_class_code,
      :company_name,
      :company_note_data,
      :company_id,
      :entry_class_code,
      :company_entry_descr,
      :desc_date,
      :effective_date,
      :settlement_date,
      :origin_status_code,
      :origin_dfi_id,
      :batch_number
    
    defaults :record_type => 5,
      :service_class_code => 200,
      :company_note_data  => '',
      :date               => lambda{ Time.now.strftime("%y%m%d") },
      :settlement_date    => '',
      :origin_status_code => ''
  end
end
