FactoryGirl.define do

  factory :order do
    ignore do
      vouchers_count 0
      contains_donation false
    end
    association :purchaser, :factory => :customer
    association :processed_by, :factory => :customer
    customer
    walkup false
    purchasemethod { Purchasemethod.find_by_shortdesc(:box_cash) }
    sold_on { Time.now }

    after_build do |order|
      if walkup
        order.customer = order.purchaser = Customer.walkup_customer
        order.processed_by ||= Customer.boxoffice_daemon
      end
    end
    after_create do |order,evaluator|
      1.upto evaluator.vouchers_count do
        order.items << FactoryGirl.create(:revenue_voucher)
      end
      if evaluator.contains_donation
        order.items << FactoryGirl.create(:donation)
      end
    end
  end

end