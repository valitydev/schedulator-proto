include "base.thrift"
include "domain.thrift"
include "payout_processing.thrift"

namespace java com.rbkmoney.damsel.schedule
namespace erlang com.rbkmoney.damsel.schedule

typedef string URL

struct RegisterJobRequest {
    // путь до сервиса, который будет исполнять Job
    1: required URL executor_service_path

    2: required Schedule schedule

    3: required GenericServiceExecutionContext context
}

struct ExecuteJobRequest {
    1: required ScheduledJobContext scheduled_job_context
    2: required GenericServiceExecutionContext service_execution_context
}

union Schedule {
    1: DominantBasedSchedule dominant_schedule
}

struct DominantBasedSchedule {
    1: required domain.BusinessScheduleRef business_schedule_ref
    2: required domain.CalendarRef calendar_ref
    3: optional domain.DataRevision revision
}

/**
 * Общий контекст выполнения какого-то абстрактного сервиса
 * Можно дополнять различными сервисами, которые должны выполнять Job-ы по расписанию
 **/
union GenericServiceExecutionContext {
    1: PayouterExecutionContext payouter_context
}

/** Конкретные контексты выполнения сервисов, чтобы выполняющий сервис знал, какую именно операцию ему совершать */
union PayouterExecutionContext {
    1: payout_processing.GeneratePayoutParams generate_payout_context // whatever you like context
}

struct ScheduledJobContext {
    1: required base.Timestamp next_fire_time
    2: required base.Timestamp prev_fire_time
    3: required base.Timestamp next_cron_time
}

union ContextValidationResponse {
    1: required list<string> errors
}

struct DeregisterJob {}
struct RemainJob {}

exception NotFoundSchedule {}
exception ScheduleAlreadyExists {}
exception BadContextProvided {
    1: required ContextValidationResponse validation_response
}

/**
* Интерфейс сервиса регистрирующего и высчитывающего расписания выполнений
**/
service Schedulator {

    void RegisterJob(1: base.ID schedule_id, 2: RegisterJobRequest context)
        throws (1: ScheduleAlreadyExists schedule_already_exists_ex, 2: BadContextProvided bad_context_provided_ex)

    void DeregisterJob(1: base.ID schedule_id)
        throws (1: NotFoundSchedule ex)
}

/**
* Интерфейс для сервисов, выполняющих Job-ы по расписанию
**/
service ScheduledJobExecutor {

    /** метод вызывается при попытке зарегистрировать Job */
    ContextValidationResponse ValidateExecutionContext(1: GenericServiceExecutionContext context)

    GenericServiceExecutionContext ExecuteJob(1: ExecuteJobRequest request)

}