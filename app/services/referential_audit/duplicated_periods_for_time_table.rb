class ReferentialAudit
  class DuplicatedPeriodsForTimeTable < Base
    include ReferentialAudit::Concerns::TimeTableBase

    def message(record, output: :console)
      "#{record_name(record, output)} has a duplicated TimeTablePeriod #{record.id}"
    end

    def find_faulty
      Chouette::TimeTablePeriod.joins("inner join time_table_periods as brother on time_table_periods.time_table_id = brother.time_table_id and time_table_periods.id <> brother.id").where("time_table_periods.period_start <= brother.period_end AND time_table_periods.period_end >= brother.period_start")
    end
  end
end