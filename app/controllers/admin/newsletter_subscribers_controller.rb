module Admin
  class NewsletterSubscribersController < BaseController
    before_action :require_admin!

    def index
      @confirmed_count = NewsletterSubscriber.confirmed.count
      @active_count    = NewsletterSubscriber.active.count

      respond_to do |format|
        format.html do
          @pagy, @subscribers = pagy(:offset, NewsletterSubscriber.recent, limit: 50)
        end
        format.csv do
          send_data csv_export, filename: "subscribers-#{Date.current}.csv",
                                type: "text/csv", disposition: "attachment"
        end
      end
    end

    def destroy
      subscriber = NewsletterSubscriber.find(params[:id])
      subscriber.destroy
      redirect_to admin_newsletter_subscribers_path, notice: "Subscriber removed."
    end

    private

    def csv_export
      CSV.generate(headers: true) do |csv|
        csv << %w[email confirmed_at subscribed_at]
        NewsletterSubscriber.active.order(:email).each do |s|
          csv << [ s.email, s.confirmed_at&.iso8601, s.created_at.iso8601 ]
        end
      end
    end
  end
end
