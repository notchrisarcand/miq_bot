describe CommitMonitorHandlers::CommitRange::SqlMigrationLabeler do
  let(:branch)         { create(:pr_branch) }
  let(:git_service)    { double("GitService", :diff => double("RuggedDiff", :new_files => new_files)) }
  let(:github_service) { stub_github_service }

  before do
    stub_sidekiq_logger
    stub_settings(:sql_migration_labeler => {:enabled_repos => [branch.repo.name]})
    expect_any_instance_of(Branch).to receive(:git_service).and_return(git_service)
  end

  context "when there are migrations" do
    let(:new_files) { ["db/migrate/20160706230546_some_migration.rb", "some/other/file.rb"] }

    it "adds a label to the PR" do
      expect(github_service).to receive(:add_issue_labels).with(branch.pr_number, "sql migration")

      described_class.new.perform(branch.id, nil)
    end
  end

  context "where there are no migrations" do
    let(:new_files) { ["some/other/file.rb"] }

    it "does not add a label to the PR" do
      expect(github_service).to_not receive(:add_issue_labels)

      described_class.new.perform(branch.id, nil)
    end
  end

  context "where there are changes to migration specs only" do
    let(:new_files) { ["spec/db/migrate/20160706230546_some_migration_spec.rb", "some/other/file.rb"] }

    it "does not add a label to the PR" do
      expect(github_service).to_not receive(:add_issue_labels)

      described_class.new.perform(branch.id, nil)
    end
  end
end
