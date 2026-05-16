import 'dart:async';

import 'package:flutter/material.dart';
import 'package:untitled/common/api_service/job_service.dart';
import 'package:untitled/common/controller/base_controller.dart';
import 'package:untitled/models/job_models.dart';

class JobListController extends BaseController {
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  List<JobOffer> jobs = [];
  bool hasMore = true;
  String? selectedContractType;
  String? selectedLocationType;
  String? selectedExperienceLevel;
  String? selectedDomain;
  String sortBy = 'date';
  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    fetchJobs();
    scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      loadMore();
    }
  }

  Future<void> fetchJobs({bool refresh = false}) async {
    if (refresh) {
      jobs.clear();
      hasMore = true;
    }
    if (!hasMore && !refresh) return;
    if (refresh) {
      hasNetworkError = false;
    }

    isLoading.value = jobs.isEmpty;
    update();

    try {
      final newJobs = await JobService.shared.fetchJobs(
        start: refresh ? 0 : jobs.length,
        keyword: searchController.text.isNotEmpty ? searchController.text : null,
        contractType: selectedContractType,
        locationType: selectedLocationType,
        experienceLevel: selectedExperienceLevel,
        domain: selectedDomain,
        sortBy: sortBy,
      );
      if (newJobs.isEmpty) {
        hasMore = false;
      } else {
        jobs.addAll(newJobs);
      }
    } catch (_) {
      hasNetworkError = true;
    }
    isLoading.value = false;
    update();
  }

  void loadMore() {
    if (!isLoading.value && hasMore) {
      fetchJobs();
    }
  }

  void onSearch(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      fetchJobs(refresh: true);
    });
  }

  void setContractFilter(String? value) {
    selectedContractType = value;
    fetchJobs(refresh: true);
  }

  void setLocationFilter(String? value) {
    selectedLocationType = value;
    fetchJobs(refresh: true);
  }

  void setExperienceFilter(String? value) {
    selectedExperienceLevel = value;
    fetchJobs(refresh: true);
  }

  void setDomainFilter(String? value) {
    selectedDomain = value;
    fetchJobs(refresh: true);
  }

  void setSortBy(String value) {
    sortBy = value;
    fetchJobs(refresh: true);
  }

  void toggleSave(int index) async {
    final job = jobs[index];
    if (job.id == null) return;
    final success = await JobService.shared.toggleSaveJob(jobId: job.id!);
    if (success) {
      jobs[index].isSaved = (job.isSaved == 1) ? 0 : 1;
      update();
    }
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    scrollController.dispose();
    searchController.dispose();
    super.onClose();
  }
}
