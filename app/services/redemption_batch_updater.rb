class RedemptionBatchUpdater

  attr_reader :showdates, :vouchertypes
  attr_accessor :valid_voucher_params, :preserve

  def initialize(showdates, vouchertypes, valid_voucher_params: {}, preserve: {})
    @showdates = showdates
    @vouchertypes = vouchertypes
    @valid_voucher_params = valid_voucher_params
    @preserve = preserve
    @errs = Hash.new { |h,k| h[k] = [] } # vouchertype => showdate_id's to which it could NOT be added
    @possible_cause = {}
    @vv = nil
  end

  def update
    # Transactionally add one or more vouchertypes to multiple showdates.  
    # If errors, collate them intelligently and fail.
    # If +valid_voucher_params+ includes a key
    # <tt>:before_showtime => val</tt>, then each valid voucher's end-sales should be overridden to be
    # +val+ prior to its showtime (+val+ must be an object that can be added/subtracted from +Time+).
    before_showtime = valid_voucher_params.delete(:before_showtime)
    ValidVoucher.transaction do
      showdates.each do |showdate|
        # if this valid-voucher exists already, edit it in place; otherwise create new.
        vouchertypes.each do |vouchertype|
          if (@vv = ValidVoucher.find_by(:showdate => showdate, :vouchertype => vouchertype))
            selectively_assign_to_existing
          else
            build_new
          end
          add_error unless @vv.save
        end
      end
      # if any errors occurred, commit none of the changes.
      raise ActiveRecord::Rollback unless @errs.empty?
    end
    @errs.empty?
  end
  
  def selectively_assign_to_existing
    args = valid_voucher_params.clone
    # special case:  start/end_sales args are a set of end_sales(1i), etc, so reject all if must be preserved
    args.reject!  { |k,v| k =~ /end_sales/ }    if preserve[:end_sales]
    args.reject!  { |k,v| k =~ /start_sales/ }  if preserve[:start_sales]
    preserve.keys.each { |k| args.delete(k) }
    # assign all remaining (non-preserved) attributes
    @vv.assign_attributes(args)
    @vv.end_sales = (showdate.thedate - before_showtime).rounded_to(:second) unless preserve[:end_sales]
  end

  def build_new
    @vv = ValidVoucher.new(valid_voucher_params.merge({:showdate => showdate, :vouchertype => vouchertype}))
    @vv.end_sales = (showdate.thedate - before_showtime).rounded_to(:second)
  end

  def add_error
    @errs[@vv.vouchertype] << vv.showdate.thedate.to_formatted_s(:showtime_brief)
    @possible_cause[@vv.vouchertype] = vv.errors.full_messages.join(', ')

  end

  def error_message
    @errs.map do |vouchertype,dates|
      "Can't add '#{vouchertype.name}' (possibly because: #{@possible_cause[vouchertype]}) to #{dates.first} and #{dates.size - 1} more dates"
    end.join('; ')
  end
end
