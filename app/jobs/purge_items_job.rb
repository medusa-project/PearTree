class PurgeItemsJob < Job

  queue_as :default

  ##
  # @param args [Array] One-element array with the UUID of the collection to
  #                     purge items from at position 0.
  #
  def perform(*args)
    collection = Collection.find_by_repository_id(args[0])

    self.task&.update(status_text: "Purging items in #{collection.title}")

    count = collection.purge
    Solr.instance.commit

    if self.task
      self.task.status_text += ": purged #{count} items"
      self.task.succeeded
    end
  end

end