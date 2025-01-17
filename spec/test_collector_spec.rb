module TestCenter::Helper
  describe TestCenter do
    describe TestCenter::Helper do
      describe TestCollector do
        before (:each) do
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with('path/to/fake.xctestrun').and_return(true)
        end
        
        it 'throws an exception for a non-existent xctestrun' do
          expect { TestCollector.new(derived_data_path: 'path/to/fake/derived_data', scheme: 'Professor') }.to(
            raise_error(FastlaneCore::Interface::FastlaneError) do |error|
              expect(error.message).to match(/Error: cannot find xctestrun file/)
            end
          )
        end

        it 'finds testable from given xctestrun' do
          allow(Plist).to receive(:parse_xml).with('path/to/fake.xctestrun').and_return({ 'AtomicBoyTests' => [] })
          test_collector = TestCollector.new(
            xctestrun: 'path/to/fake.xctestrun'
          )
          expect(test_collector.testables).to eq(['AtomicBoyTests'])
        end

        it 'finds testables from derived xctestrun' do
          allow(File).to receive(:exist?).with("path/to/fake/derived_data/Build/Products/Professor_Blahblah.xctestrun").and_return(true)
          allow(Dir).to receive(:glob).with("path/to/fake/derived_data/Build/Products/*.xctestrun").and_return(['path/to/fake/derived_data/Build/Products/Professor_Blahblah.xctestrun'])
          allow(Plist).to receive(:parse_xml).with("path/to/fake/derived_data/Build/Products/Professor_Blahblah.xctestrun").and_return({ 'AtomicBoyTests' => [], 'AtomicBoyUITests' => [] })
          test_collector = TestCollector.new(
            derived_data_path: 'path/to/fake/derived_data',
            scheme: 'Professor'
          )
          expect(test_collector.testables).to eq(['AtomicBoyTests', 'AtomicBoyUITests'])
        end

        it 'finds testables from default xctestrun when given :skip_build' do
          FAKE_DEFAULT_DERIVED_DATA_PATH = 'path/to/fake/default_derived_data'
          XCTEST_RUN_FILENAME = 'Professor_Blahblah.xctestrun'
          allow(File).to receive(:exist?).with("#{FAKE_DEFAULT_DERIVED_DATA_PATH}/Build/Products/#{XCTEST_RUN_FILENAME}").and_return(true)
          allow(Dir).to receive(:glob).with("#{FAKE_DEFAULT_DERIVED_DATA_PATH}/Build/Products/*.xctestrun").and_return(["#{FAKE_DEFAULT_DERIVED_DATA_PATH}/Build/Products/#{XCTEST_RUN_FILENAME}"])
          allow(Plist).to receive(:parse_xml).with("#{FAKE_DEFAULT_DERIVED_DATA_PATH}/Build/Products/#{XCTEST_RUN_FILENAME}").and_return({ 'AtomicBoyTests' => [], 'AtomicBoyUITests' => [] })
          mocked_project = OpenStruct.new
          allow(mocked_project).to receive(:build_settings).and_return("#{FAKE_DEFAULT_DERIVED_DATA_PATH}/blah1/blah2/blah3")
          allow(File).to receive(:expand_path).with('../../..', "#{FAKE_DEFAULT_DERIVED_DATA_PATH}/blah1/blah2/blah3").and_return(FAKE_DEFAULT_DERIVED_DATA_PATH)
          allow(Scan).to receive(:project).and_return(mocked_project)
          test_collector = TestCollector.new(
            skip_build: true,
            scheme: 'Professor'
          )
          expect(test_collector.testables).to eq(['AtomicBoyTests', 'AtomicBoyUITests'])
        end

        it 'calls to testables :only_testing returns those testables' do
          expect(Plist).not_to receive(:parse_xml)
          expect(Fastlane::Actions::TestsFromXctestrunAction).not_to receive(:run)
          test_collector = TestCollector.new(
            xctestrun: 'path/to/fake.xctestrun',
            only_testing: [
              'AtomicBoyTests/AtomicBoyTests/testExample1',
              'AtomicBoyUITests/AtomicBoyUITests/testExample3',
              'AtomicBoyUITests/AtomicBoyUITests/testExample4'
            ]
          )
          result = test_collector.testables
          expect(result).to include('AtomicBoyTests', 'AtomicBoyUITests')
        end

        it 'calls to testables :only_testing with a String returns an array with a testable' do
          expect(Plist).not_to receive(:parse_xml)
          expect(Fastlane::Actions::TestsFromXctestrunAction).not_to receive(:run)
          test_collector = TestCollector.new(
            xctestrun: 'path/to/fake.xctestrun',
            only_testing: 'AtomicBoyTests'
          )
          result = test_collector.testables
          expect(result).to include('AtomicBoyTests')
        end

        it 'calls to testables_tests returns Hash of only_testing' do
          expect(Fastlane::Actions::TestsFromXctestrunAction).not_to receive(:run)
          test_collector = TestCollector.new(
            xctestrun: 'path/to/fake.xctestrun',
            only_testing: [
              'AtomicBoyTests/AtomicBoyTests/testExample1',
              'AtomicBoyUITests/AtomicBoyUITests/testExample3',
              'AtomicBoyUITests/AtomicBoyUITests/testExample4'
            ]
          )
          result = test_collector.testables_tests
          expect(result).to include(
            'AtomicBoyTests' => [
              'AtomicBoyTests/AtomicBoyTests/testExample1'
            ],
            'AtomicBoyUITests' => [
              'AtomicBoyUITests/AtomicBoyUITests/testExample3',
              'AtomicBoyUITests/AtomicBoyUITests/testExample4'
            ]
          )
        end

        it 'calls to testables_tests returns Hash of only_testing' do
          test_collector = TestCollector.new(
            xctestrun: 'path/to/fake.xctestrun',
            only_testing: ['AtomicBoyTests']
          )
          allow(test_collector).to receive(:xctestrun_known_tests).and_return(
            'AtomicBoyTests' => ['AtomicBoyTests']
          )
          result = test_collector.testables_tests
          expect(result).to include(
            'AtomicBoyTests' => ['AtomicBoyTests']
          )
        end

        it 'calls to testables_tests returns Hash of without tests from :skip_testing' do
          allow(File).to receive(:exist?).with('path/to/fake.xctestrun').and_return(true)
          expect(Fastlane::Actions::TestsFromXctestrunAction).to receive(:run)
            .and_return(
              'AtomicBoyTests' => [
                'AtomicBoyTests/AtomicBoyTests/testExample1',
                'AtomicBoyTests/AtomicBoyTests/testExample2',
                'AtomicBoyTests/AtomicBoyTests/testExample3',
                'AtomicBoyTests/AtomicBoyTests/testExample4'
              ],
              'AtomicBoyUITests' => [
                'AtomicBoyUITests/AtomicBoyUITests/testExample1',
                'AtomicBoyUITests/AtomicBoyUITests/testExample2',
                'AtomicBoyUITests/AtomicBoyUITests/testExample3',
                'AtomicBoyUITests/AtomicBoyUITests/testExample4'
              ]
            )
          test_collector = TestCollector.new(
            xctestrun: 'path/to/fake.xctestrun',
            skip_testing: [
              'AtomicBoyTests/AtomicBoyTests/testExample2',
              'AtomicBoyTests/AtomicBoyTests/testExample3',
              'AtomicBoyUITests/AtomicBoyUITests/testExample4'
            ]
          )
          result = test_collector.testables_tests
          expect(result).to include(
            'AtomicBoyTests' => [
              'AtomicBoyTests/AtomicBoyTests/testExample1',
              'AtomicBoyTests/AtomicBoyTests/testExample4'
            ],
            'AtomicBoyUITests' => [
              'AtomicBoyUITests/AtomicBoyUITests/testExample1',
              'AtomicBoyUITests/AtomicBoyUITests/testExample2',
              'AtomicBoyUITests/AtomicBoyUITests/testExample3'
            ]
          )
        end

        it 'multiple testables_tests calls tests_from_xctestrun action once' do
          test_collector = TestCollector.new(
            xctestrun: 'path/to/fake.xctestrun'
          )
          expected_result = {
            'AtomicBoyTests' => [
              'AtomicBoyTests/AtomicBoyTests/testExample1',
              'AtomicBoyTests/AtomicBoyTests/testExample2',
              'AtomicBoyTests/AtomicBoyTests/testExample3',
              'AtomicBoyTests/AtomicBoyTests/testExample4'
            ]
          }
          allow(File).to receive(:exist?).with('path/to/fake.xctestrun').and_return(true)
          expect(Fastlane::Actions::TestsFromXctestrunAction).to receive(:run)
            .and_return(expected_result).once
          result = test_collector.testables_tests
          expect(result).to include(expected_result)
          result = test_collector.testables_tests
          expect(result).to include(expected_result)
        end

        it 'has more testables than the number of requested batches' do
          mock_xctestrun = {
            'AtomicBoyTests' => [
              'AtomicBoyTests/AtomicBoyTests/testExample1',
              'AtomicBoyTests/AtomicBoyTests/testExample2',
              'AtomicBoyTests/AtomicBoyTests/testExample3',
              'AtomicBoyTests/AtomicBoyTests/testExample4'
            ],
            'AtomicBoyUITests' => [
              'AtomicBoyUITests/AtomicBoyUITests/testExample1',
              'AtomicBoyUITests/AtomicBoyUITests/testExample2',
              'AtomicBoyUITests/AtomicBoyUITests/testExample3',
              'AtomicBoyUITests/AtomicBoyUITests/testExample4'
            ],
            'AtomicGirlTests' => [
              'AtomicGirlTests/AtomicGirlTests/testExample1',
              'AtomicGirlTests/AtomicGirlTests/testExample2',
              'AtomicGirlTests/AtomicGirlTests/testExample3',
              'AtomicGirlTests/AtomicGirlTests/testExample4'
            ],
            'AtomicGirlUITests' => [
              'AtomicGirlUITests/AtomicGirlUITests/testExample1',
              'AtomicGirlUITests/AtomicGirlUITests/testExample2',
              'AtomicGirlUITests/AtomicGirlUITests/testExample3',
              'AtomicGirlUITests/AtomicGirlUITests/testExample4'
            ],
            'AtomicPuppyTests' => [
              'AtomicPuppyTests/AtomicPuppyTests/testExample1',
              'AtomicPuppyTests/AtomicPuppyTests/testExample2',
              'AtomicPuppyTests/AtomicPuppyTests/testExample3',
              'AtomicPuppyTests/AtomicPuppyTests/testExample4'
            ],
            'AtomicPuppyUITests' => [
              'AtomicPuppyUITests/AtomicPuppyUITests/testExample1',
              'AtomicPuppyUITests/AtomicPuppyUITests/testExample2',
              'AtomicPuppyUITests/AtomicPuppyUITests/testExample3',
              'AtomicPuppyUITests/AtomicPuppyUITests/testExample4'
            ]
          }
          allow(Plist).to receive(:parse_xml).and_return(mock_xctestrun)
          allow(File).to receive(:exist?).with('path/to/fake.xctestrun').and_return(true)
          expect(Fastlane::Actions::TestsFromXctestrunAction).to receive(:run)
            .and_return(mock_xctestrun)

          test_collector = TestCollector.new(
            xctestrun: 'path/to/fake.xctestrun',
            batch_count: 3
          )
          expect(test_collector.test_batches.size).to eq(12)
        end
      end
    end
  end
end
